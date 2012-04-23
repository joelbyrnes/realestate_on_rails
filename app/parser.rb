require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'
require 'json'

def parse_property(result)
  div_propInfo = result.xpath(".//div[@class='propertyInfo']")[0]
  a_prop = div_propInfo.xpath(".//a[@rel='listingName']")[0]

  prop = {}

  prop[:id] = /\d+/.match(a_prop['href'])[0]
  puts prop[:id]

  prop[:photo_url] = div_propInfo.xpath(".//div[@class='photo']/a/img")[0]['src']
  puts prop[:photo_url]

  times = result.xpath(".//div[@class='times']")[0]
  date_content = times.xpath(".//ul/li[@class='date']")[0].content
  # TODO this only grabs the first timeslot, sometimes there is more LI
  time_content = times.xpath(".//ul/li/span")[0].content

  times = time_content.split(" - ")
  time_start = DateTime.strptime(date_content + " " + times[0], '%a %d - %b %I:%M%p')
  time_end = DateTime.strptime(date_content + " " + times[1], '%a %d - %b %I:%M%p')
  puts time_start
  puts time_end

  # TODO use a 2nd table for inspections
  inspections = { start: time_start, end: time_end}

  prop[:inspections] = inspections
  prop[:inspection_start] = time_start
  prop[:inspection_end] = time_end

  return prop
end

def parse_json(json)
  # remove variable declaration and following crap
  json = json.sub("LMI.Data.listings=", '').sub("];", "]")
  json = json.sub(/LMI.Data.listGroup.*/, '')
  # wrap the keys in quotes
  json = json.gsub(/([A-Za-z0-9]+):/, '"\1":')

  data = JSON.parse(json)

  keys = %w(id name city displayPrice latitude longitude prettyDetailsUrl note)

  data.map { |d|
    {
        id: d["id"],
        title: d["name"],
        city: d["city"],
        display_price: d["displayPrice"],
        latitude: d["latitude"],
        longitude: d["longitude"],
        url: "http://www.realestate.com.au" + d["prettyDetailsUrl"],
        note: d["note"] == "" ? "" : "(from RE) " + d["note"]
    }
  }
end

def parse_inspections(html)
  doc = Nokogiri::HTML.parse(html)

  json = doc.xpath("//script[contains(text(), 'LMI.Data.listings')]")[0].content
  jsondata = parse_json(json)

  results = doc.xpath("//div[contains(@class, 'resultBody') and @class!='resultBodyWrapper']")
  htmldata = results.map do |result|
    parse_property result
  end

  # pull from HTML what json doesn't have
  # TODO some way to merge hashmaps on id?
  htmldata.map do |h|
    data = jsondata.find { |j| j[:id] == h[:id] }
    data[:photo_url] = h[:photo_url]
    data
  end
end

def post_prop(prop)
  # POST http://localhost:3000/properties/create with property[title]...
  # year property[seen_date(1i)]
  # month property[seen_date(2i)]
  # day property[seen_date(3i)]

  post_data = Net::HTTP.post_form(URI.parse('http://localhost:3000/properties'), {
      'property[title]' => prop[:title],
      'property[unique_id]' => prop[:id],
      'property[url]' => prop[:url],
      'property[photo_url]' => prop[:photo_url],
      'property[display_price]' => prop[:display_price],
      'property[latitude]' => prop[:latitude],
      'property[longitude]' => prop[:longitude],
      'property[note]' => prop[:note],
      'commit' => 'Create Property'
    }
  )

  puts post_data.body
end

htmlfile = File.open('../inspection_times.html')
html = htmlfile.read
htmlfile.close

data = parse_inspections html

puts data

# send data to new web service
data.each do |prop|
  post_prop(prop)
end


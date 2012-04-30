require 'nokogiri'
require 'net/http'
require 'json'
require 'active_support/core_ext'

def parse_property(result)
  div_propInfo = result.xpath(".//div[@class='propertyInfo']")[0]
  a_prop = div_propInfo.xpath(".//a[@rel='listingName']")[0]

  prop = {}

  prop[:id] = /\d+/.match(a_prop['href'])[0]

  prop[:photo_url] = div_propInfo.xpath(".//div[@class='photo']/a/img")[0]['src']

  times = result.xpath(".//div[@class='times']")[0]
  date_content = times.xpath(".//ul/li[@class='date']")[0].content

  times_lis = times.xpath(".//ul/li/span")

  tz = "+10:00"

  prop[:inspections] = times_lis.map { |li|
    times = li.content.split(" - ")
    time_start = DateTime.strptime(date_content + " " + times[0] + tz, '%a %d - %b %I:%M%p%z')
    time_end = DateTime.strptime(date_content + " " + times[1] + tz, '%a %d - %b %I:%M%p%z')
    { start: time_start, end: time_end}
  }
  puts "#{prop[:id]} - #{prop[:inspections]}"

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
  # POST http://localhost:3000/properties with property[title]...

  data = {
      'property[title]' => prop[:title],
      'property[external_id]' => prop[:id],
      'property[url]' => prop[:url],
      'property[photo_url]' => prop[:photo_url],
      'property[display_price]' => prop[:display_price],
      'property[latitude]' => prop[:latitude],
      'property[longitude]' => prop[:longitude],
      'property[note]' => prop[:note],
      'commit' => 'Create Property'
  }

  uri = URI.parse('http://localhost:3000/properties')

  response = Net::HTTP.post_form(uri, data)

  puts "create property #{prop[:title]}: #{response.code}: #{response.message}"

  if response.code == "200" || response.code == "302"
    puts "Success creating or updating"
  else
    puts "fail: Response #{response.code}, #{response.message}"

  end

end

htmlfile = File.open('../inspection_times.html')
html = htmlfile.read
htmlfile.close

data = parse_inspections html

# send data to new web service
data.each do |prop|
  post_prop(prop)
end

#post_prop(data[0])


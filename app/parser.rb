require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'
require 'json'

class PropertyImport
  attr_accessor :title, :unique_id, :url, :photo_url, :address, :price_string, :note
  
  def initialize(unique_id)
    @unique_id = unique_id
  end
  
  def to_s
    "Property: " + @unique_id + ", " + @title
  end
end

def parse_property(result)
  div_propInfo = result.xpath(".//div[@class='propertyInfo']")[0]
  a_prop = div_propInfo.xpath(".//a[@rel='listingName']")[0]

  url = "http://www.realestate.com.au" + a_prop['href']
  id = /\d+/.match(url)[0]

  prop = PropertyImport.new(id)
  prop.url = url

  prop.title = a_prop.content

  img_photo = div_propInfo.xpath(".//div[@class='photo']/a/img")[0]
  prop.photo_url = img_photo['src']

  puts prop.unique_id
  puts prop.title
  puts prop.url
  puts prop.photo_url
  
  times = result.xpath(".//div[@class='times']")[0]
  date = times.xpath(".//ul/li[@class='date']")[0].content
  time = times.xpath(".//ul/li/span")[0].content
  puts date
  puts time

  p_price = result.xpath(".//div[@class='priceInfo']/p")[0]
  if p_price['title']
    prop.price_string = p_price['title']
  else
    prop.price_string = p_price.xpath(".//span[@class='hidden']")[0].content.sub(" none", "")
  end
  puts prop.price_string

  note_p = result.xpath(".//div[@class='note']/p")[0]
  if note_p
    prop.note = "(from RE) " + note_p.content
    puts prop.note
  end

  return prop
end

def parse_json(json)
  # remove variable declaration and following crap
  json = json.sub("LMI.Data.listings=", '').sub(";", "")
  json = json.sub(/LMI.Data.listGroup.*/, '')
  # wrap the keys in quotes
  json = json.gsub(/([A-Za-z0-9]+):/, '"\1":')

  data = JSON.parse(json)

  keys = %w(id name city displayPrice latitude longitude prettyDetailsUrl note)

  data.map { |d|
    {
        :id => d["id"],
        :title => d["name"],
        :city => d["city"],
        :display_price => d["displayPrice"],
        :latitude => d["latitude"],
        :longitude => d["longitude"],
        :url => "http://www.realestate.com.au" + d["prettyDetailsUrl"],
        :note => d["note"] == "" ? "" : "(from RE) " + d["note"]
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
  htmldata.map do |h|
    data = jsondata.find { |j| j[:id] == h.unique_id }
    data[:photo_url] = h.photo_url
    data
  end
end

def post_prop(prop)
  # POST http://localhost:3000/properties/create with property[title]...
  # year property[seen_date(1i)]
  # month property[seen_date(2i)]
  # day property[seen_date(3i)]

  post_data = Net::HTTP.post_form(URI.parse('http://localhost:3000/properties'), {
      'property[title]'=> prop[:title],
      'property[unique_id]'=> prop[:id],
      'property[url]'=> prop[:url],
      'property[photo_url]'=> prop[:photo_url],
      'property[display_price]'=> prop[:display_price],
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


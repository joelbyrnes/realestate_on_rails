require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'

class PropertyImport
  attr_accessor :title, :site_id, :url, :photo_url, :address, :seen_date, :price_string
  
  def initialize(title, site_id, url, photo_url)
    @title = title
    @site_id = site_id
    @url = url
    @photo_url = photo_url
  end
  
  def to_s
    "Property: " + @site_id + ", " + @title
  end
end

def parse_property(result)
  div_propInfo = result.xpath(".//div[@class='propertyInfo']")[0]
  img_photo = div_propInfo.xpath(".//div[@class='photo']/a/img")[0]
  
  a_prop = div_propInfo.xpath(".//a[@rel='listingName']")[0]
  title = a_prop.content
  # or just http://www.realestate.com.au/123456789
  
  # prop = {}
  
  url = "http://www.realestate.com.au" + a_prop['href']
  id = /\d+/.match(url)[0]
  photo_url = img_photo['src']
  puts id
  puts title
  puts url
  puts photo_url
  
  times = result.xpath(".//div[@class='times']")[0]
  date = times.xpath(".//ul/li[@class='date']")[0].content
  time = times.xpath(".//ul/li/span")[0].content
  puts date
  puts time

  prop = PropertyImport.new(title, id, url, photo_url)

  p_price = result.xpath(".//div[@class='priceInfo']/p")[0]
  if p_price['title']
    price_string = p_price['title']
  else
    price_string = p_price.xpath(".//span[@class='hidden']")[0].content.sub(" none", "")
  end
  puts price_string
  prop.price_string = price_string
  
  return prop
end

def parse_inspections(html)
  doc = Nokogiri::HTML.parse(html)
  results = doc.xpath("//div[contains(@class, 'resultBody') and @class!='resultBodyWrapper']")

  results.map do |result| 
    parse_property result
  end
end

def post_prop(prop)
  # POST http://localhost:3000/properties/create with property[title]...
  # year property[seen_date(1i)]
  # month property[seen_date(2i)]
  # day property[seen_date(3i)]

  post_data = Net::HTTP.post_form(URI.parse('http://localhost:3000/properties'), {
      'property[title]'=> prop.title,
      'property[site_id]'=> prop.site_id,
      'property[url]'=> prop.url,
      'property[photo_url]'=> prop.photo_url,
      'property[price_string]'=> prop.price_string,
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


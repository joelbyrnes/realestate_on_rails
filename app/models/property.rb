class Property < ActiveRecord::Base
  attr_accessible :address, :display_price, :latitude, :longitude, :note, :photo_url, :seen_date, :title, :unique_id, :url
end

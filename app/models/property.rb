class Property < ActiveRecord::Base
  attr_accessible :address, :photo_url, :price_string, :seen_date, :site_id, :title, :url
end

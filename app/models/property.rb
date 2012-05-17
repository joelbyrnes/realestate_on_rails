class Property < ActiveRecord::Base
  attr_accessible :address, :display_price, :external_id, :latitude, :longitude, :note, :photo_url, :rating, :seen_date, :title, :url
  has_many :inspections

  def self.search(search)
    if search
      find(:all, :conditions => ['title LIKE ?', "%#{search}%"])
    else
      find(:all)
    end
  end

end

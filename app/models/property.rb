class Property < ActiveRecord::Base
  attr_accessible :address, :display_price, :external_id, :latitude, :longitude, :note, :photo_url, :rating, :seen_date, :title, :url
  has_many :inspections

  def self.search(params)

    #conditions = {}
    #conditions['title LIKE ?'] = "%#{params[:title]}%" unless params[:title].blank?
    #conditions[:city] = city unless city.blank?
    #conditions[:zip] = zip unless zip.blank?
    #conditions[:state] = state unless state.blank?
    #Address.find(:all, :conditions => conditions)

    if params[:title]
      find(:all, :conditions => ['title LIKE ?', "%#{params[:title]}%"])
    else
      find(:all)
    end
  end

end

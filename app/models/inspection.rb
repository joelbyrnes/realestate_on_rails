class Inspection < ActiveRecord::Base
  attr_accessible :end, :note, :property_id, :start
  belongs_to :property
end

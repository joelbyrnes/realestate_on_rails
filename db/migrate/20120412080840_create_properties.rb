class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :title
      t.string :site_id
      t.string :url
      t.string :photo_url
      t.string :address
      t.date :seen_date
      t.string :price_string

      t.timestamps
    end
  end
end

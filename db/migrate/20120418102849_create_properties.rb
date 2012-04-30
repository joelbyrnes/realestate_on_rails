class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :title
      t.string :external_id
      t.string :url
      t.string :photo_url
      t.string :address
      t.date :seen_date
      t.string :display_price
      t.string :note
      t.float :latitude
      t.float :longitude

      t.timestamps
    end

    add_index :properties, [:external_id], :unique => true

  end
end

class CreateInspections < ActiveRecord::Migration
  def change
    create_table :inspections do |t|
      t.datetime :start
      t.datetime :end
      t.string :note
      t.integer :property_id

      t.timestamps
    end
  end
end

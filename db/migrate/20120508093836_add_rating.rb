class AddRating < ActiveRecord::Migration
  def change
    change_table :properties do |t|
      t.integer :rating, :default => 0
    end
    Property.update_all ["rating = ?", 0]
  end
end

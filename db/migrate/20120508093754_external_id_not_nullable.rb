class ExternalIdNotNullable < ActiveRecord::Migration
  def change
    change_column :properties, :external_id, :string, :null => false
  end
end

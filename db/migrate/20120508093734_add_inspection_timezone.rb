class AddInspectionTimezone < ActiveRecord::Migration
  def change
    change_table :inspections do |t|
      t.string :timezone, :default => "Brisbane"
    end
    Inspection.update_all ["timezone = ?", "Brisbane"]
  end
end

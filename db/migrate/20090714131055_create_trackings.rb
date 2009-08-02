class CreateTrackings < ActiveRecord::Migration
  def self.up
    create_table :trackings do |t|
      t.text :generated_tracking_file
      t.references :orders

      t.timestamps
    end
  end

  def self.down
    drop_table :trackings
  end
end

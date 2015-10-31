class CreateListingsTable < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.st_point :location, srid: 4326
      t.integer :ask
      t.integer :bedrooms
      t.string :title
      t.string :address
      t.datetime :posting_date, null: true

      t.timestamps
    end
  end
end

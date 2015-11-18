class AddJsonColumnToListings < ActiveRecord::Migration
  def change
  	add_column :listings, :payload, :json
  end
end

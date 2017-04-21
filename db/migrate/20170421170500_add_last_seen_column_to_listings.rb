class AddLastSeenColumnToListings < ActiveRecord::Migration
  def change
  	add_column :listings, :last_seen, :datetime
  end
end

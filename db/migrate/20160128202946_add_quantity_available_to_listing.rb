class AddQuantityAvailableToListing < ActiveRecord::Migration
  def change
    add_column :listings, :quantity_available, :integer
  end
end

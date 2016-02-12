class AddDepositToListing < ActiveRecord::Migration
  def change
  	add_column :listings, :deposit_cents, :integer
  end
end

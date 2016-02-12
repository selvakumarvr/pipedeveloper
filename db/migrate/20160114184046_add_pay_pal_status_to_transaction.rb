class AddPayPalStatusToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :paypal_status, :string
  end
end

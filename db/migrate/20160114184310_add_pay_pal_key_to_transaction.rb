class AddPayPalKeyToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :paypal_paykey, :text
  end
end

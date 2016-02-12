class AddPayPalPayerToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :paypal_payer_email, :string
  end
end

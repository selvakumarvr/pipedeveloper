class AddPayPalModalInitiatedToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :paypal_initiated, :boolean
  end
end

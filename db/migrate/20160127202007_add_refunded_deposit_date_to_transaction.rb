class AddRefundedDepositDateToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :deposit_refunded_at, :datetime
  end
end

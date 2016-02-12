class AddDepositToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :deposit_cents, :integer
  end
end

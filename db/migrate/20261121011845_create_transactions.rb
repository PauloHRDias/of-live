class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :external_id
      t.date :date
      t.integer :amount_cents
      t.string :merchant_name
      t.string :description

      t.timestamps
    end
    add_index :transactions, :external_id, unique: true
  end
end

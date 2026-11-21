class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id
      t.string :institution
      t.string :account_type
      t.integer :last_balance
      t.string :currency

      t.timestamps
    end
    add_index :accounts, :external_id, unique: true
  end
end

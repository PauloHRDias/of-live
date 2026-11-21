class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id
      t.string :scope

      t.timestamps
    end
    add_index :consents, :external_id, unique: true
  end
end

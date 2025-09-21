class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.text :description
      t.string :url
      t.datetime :last_checked_at
      t.boolean :active
      t.string :reference
      t.integer :kind, default: 0

      t.timestamps
    end
  end
end

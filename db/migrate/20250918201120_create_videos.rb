class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :reference
      t.string :title
      t.text :description
      t.integer :duration
      t.datetime :uploaded_at
      t.string :url
      t.string :thumbnail_url
      t.integer :status
      t.integer :download_status

      t.timestamps
    end
  end
end

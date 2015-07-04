class CreateChildPhotos < ActiveRecord::Migration
  create_table :child_photos do |t|
    t.string      :url
    t.string      :caption
    t.references  :child, index: true, foreign_key: true

    t.timestamps null: false
  end
  add_index :child_photos, [:child_id, :created_at]
end

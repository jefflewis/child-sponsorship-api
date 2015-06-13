class CreateChildren < ActiveRecord::Migration
  def change
    create_table :children do |t|
      t.string      :name
      t.string      :description
      t.references  :user, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :children, [:user_id, :created_at]
  end
end

class AddSessionDigestToUsers < ActiveRecord::Migration
  def change
    add_column :users, :session_digest, :string
  end
end

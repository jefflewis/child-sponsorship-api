class AddBirthdateAndGenderToChildren < ActiveRecord::Migration
  def change
    add_column :children, :gender, :string
    add_column :children, :birthdate, :date
  end
end

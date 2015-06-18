require 'sinatra/activerecord'

class Child < ActiveRecord::Base
  belongs_to :user
  validates :user_id,       presence: true
  validates :name,          presence: true
  validates :description,   presence: true

  def to_json
    {
      name:         name,
      description:  description,
      user_id:      user_id
    }.to_json
  end
end


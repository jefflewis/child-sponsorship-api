require 'sinatra/activerecord'

class Child < ActiveRecord::Base
  belongs_to :user
  validates :name,          presence: true
  validates :description,   presence: true
  validates :birthdate,     presence: true
  validates :gender,        presence: true

  def to_json
    self.to_hash.to_json
  end

  def to_hash
    {
      name:         name,
      description:  description,
      birthdate:    birthdate,
      gender:       gender,
      user_id:      user_id
    }
  end
end

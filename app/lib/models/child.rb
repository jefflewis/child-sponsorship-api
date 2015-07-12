require 'sinatra/activerecord'

class Child < ActiveRecord::Base
  belongs_to  :user
  has_many    :child_photos,  dependent:  :destroy
  validates   :name,          presence:   true
  validates   :description,   presence:   true
  validates   :birthdate,     presence:   true
  validates   :gender,        presence:   true

  def to_hash
    {
      id:           id,
      name:         name,
      description:  description,
      birthdate:    birthdate,
      age:          self.age,
      gender:       gender,
      child_photos: child_photos,
      user_id:      user_id
    }
  end

  def to_json
    self.to_hash.to_json
  end

  def age
    now = Time.now.utc.to_date
    now.year - birthdate.year - (birthdate.to_date.change(:year => now.year) > now ? 1 : 0)
  end
end

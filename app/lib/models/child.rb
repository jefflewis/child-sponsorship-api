require 'sinatra/activerecord'

class Child < ActiveRecord::Base
  belongs_to :user
  validates :user_id,       presence: true
  validates :name,          presence: true
  validates :description,   presence: true
end
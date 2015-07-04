require 'sinatra/activerecord'

class ChildPhoto < ActiveRecord::Base
  belongs_to  :child
  validates   :url,           presence: true

  def to_hash
    {
      id:           id,
      name:         url,
      caption:      caption,
      child_id:     child_id
    }
  end

  def to_json
    self.to_hash.to_json
  end
end

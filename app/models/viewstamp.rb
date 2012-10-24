class Viewstamp
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :game
  field :viewers, :type => Integer
  field :channels, :type => Integer
  field :twitch_viewers, :type => Integer
  field :twitch_channels, :type => Integer
  field :owned_viewers, :type => Integer
  field :owned_channels, :type => Integer
end

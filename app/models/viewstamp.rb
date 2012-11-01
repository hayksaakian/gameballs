class Viewstamp
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :game
  field :viewers, :type => Integer, :default => 0
  field :channels, :type => Integer, :default => 0
  field :twitch_viewers, :type => Integer, :default => 0
  field :twitch_channels, :type => Integer, :default => 0
  field :owned_viewers, :type => Integer, :default => 0
  field :owned_channels, :type => Integer, :default => 0
end

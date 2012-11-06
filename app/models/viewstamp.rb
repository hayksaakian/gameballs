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
  field :timestamp, :type => DateTime

  def self.migrate_old_data
  	old_data = Viewstamp.where(:timestamp => nil)
  	old_data.each do |vs|
  		vs.update_attribute(:timestamp, vs.created_at)
  	end
  end
end

require 'net/http'
require 'open-uri'
require 'json'
class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :viewstamps
  field :name, :type => String
  field :owned_name, :type => String
  field :owned_game_id => String
  field :twitch_game_id => String
  field :current_viewers => Integer, :default => 0
  field :current_channels => Integer, :default => 0
  #In this case, the own3d name has to be authoritative

  def self.update_counts
  	guid = SecureRandom.uuid
  	Game.get_twitch(guid)
  	Game.get_owned(guid)
  	Game.all.each do |gm|
  		if gm.viewstamps.any?
	  		gm.current_viewers = gm.viewstamps.last.viewers
	  		gm.current_channels = gm.viewstamps.last.channels
	  		gm.save
	  	end
	  end
  end
  #both are class methods, not instance mathods
  def self.get_twitch(timestamp_guid)
  	url = "https://api.twitch.tv/kraken/games/top?limit=75" 
  	response = JSON.parse(Net::HTTP.get(url))
  	top = response['top']
  	top.each do |gm|
  		raw_response = gm
  		name = gm['game']['name']
  		twitch_id = gm['game']['_id']
  		viewers = gm['viewers']
  		channels = gm['channels']
  		the_game = Game.find_or_initialize_by(twitch_game_id: twitch_id)
  		if the_game.name == nil
  			the_game.update_attribute(:name, name)
  		end
  		vs = the_game.viewstamps.find_or_initialize_by(timestamp_guid: timestamp_guid)
  		vs.viewers += viewers
  		vs.channels += channels
  		vs.twitch_viewers = viewers
  		vs.twitch_channels = channels
  		vs.save
  	end
  end
  def self.get_owned(timestamp_guid)
  	url = "http://api.own3d.tv/rest/live/list.json?limit=1000"
  	live_streams = JSON.parse(Net::HTTP.get(url))
  	idx = Ownedindex.first.name_to_id_map
  	games_already_checked = []
  	live_streams.each do |st|
  		game_name = st['game_name']
  		if not games_already_checked.include?(game_name)
	  		owned_game_id = idx[game_name]
	  		the_game = Game.find_or_initialize_by(owned_game_id: owned_game_id)
	  		if the_game.name == nil
	  			the_game.update_attribute(:name, name)
	  		end
	  		gm_url = url+'&gameid='+owned_game_id
		  	game_streamers = JSON.parse(Net::HTTP.get(gm_url))
		  	vs = the_game.viewstamps.find_or_initialize_by(timestamp_guid: timestamp_guid)
		  	game_streamers.each do |strmr|
		  		vs.viewers += strmr['live_viewers']
		  		vs.owned_viewers += strmr['live_viewers']
		  		vs.owned_channels += 1
		  		vs.channels += 1
		  	end
		  	vs.save
		  	games_already_checked.push(game_name)
		  end
  	end
	end
end
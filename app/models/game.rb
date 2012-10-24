require 'net/http'
require "net/https"
require 'open-uri'
require 'json'
class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :viewstamps
  field :name, :type => String
  field :owned_name, :type => String
  field :owned_game_id, :type => String
  field :twitch_game_id, :type => String
  field :current_viewers, :type => Integer, :default => 0
  field :current_channels, :type => Integer, :default => 0
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
  	url = URI.parse("https://api.twitch.tv/kraken/games/top?limit=75") 
  	http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Get.new(url.request_uri)
  	response = JSON.parse(http.request(request).body)

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
  	url = URI.parse("http://api.own3d.tv/rest/live/list.json?limit=1000")
  	rsl = Net::HTTP.get(url)
  	live_streams = JSON.parse(rsl)
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
	  		gm_url = URI.parse('http://api.own3d.tv/rest/live/list.json?limit=1000&gameid='+owned_game_id.to_s)
	  		gm_rsl = Net::HTTP.get(gm_url)
		  	game_streamers = JSON.parse(gm_rsl)
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
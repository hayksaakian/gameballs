require 'net/http'
require "net/https"
require 'open-uri'
require 'json'
class Game
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :viewstamps, :dependent => :destroy
  field :name, :type => String
  field :twitch_name, :type => String
  field :owned_name, :type => String
  field :owned_game_id, :type => String
  field :twitch_game_id, :type => String
  field :current_viewers, :type => Integer, :default => 0
  field :current_channels, :type => Integer, :default => 0
  field :hidden, :type => Boolean, :default => true
  #In this case, the own3d name has to be authoritative

  def self.update_counts
  	guid = SecureRandom.uuid
  	Game.get_twitch(guid)
    puts 'done with twitch'
  	Game.get_owned(guid)
    puts 'done with own3d'
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
  	url = URI.parse("https://api.twitch.tv/kraken/games/top?limit=100") 
  	http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Get.new(url.request_uri)
  	response = JSON.parse(http.request(request).body)

  	top = response['top']
  	top.each do |gm|
  		name = gm['game']['name']
  		twitch_id = gm['game']['_id']
  		viewers = gm['viewers'].to_i
  		channels = gm['channels'].to_i


      #find games whose name starts with 'the_game_name'
      re = Regexp.new(name, 'i')
      games = Game.where(name: re)
      #if none exist
      if games.count == 0
        #create one
        the_game = Game.find_or_initialize_by(twitch_name: name)
      else
        #select the first one
        the_game = games.first
        if the_game.twitch_name == nil
          the_game.twitch_name = name
        end
      end
  		if the_game.name == nil
  			the_game.name = name
  		end
  		vs = the_game.viewstamps.find_or_initialize_by(timestamp_guid: timestamp_guid)
  		vs.viewers += viewers
  		vs.channels += channels
  		vs.twitch_viewers = viewers
  		vs.twitch_channels = channels
  		vs.save
      the_game.save
  	end
  end
  def self.get_owned(timestamp_guid)
  	url = URI.parse("http://api.own3d.tv/rest/live/list.json?limit=1000")
  	rsl = Net::HTTP.get(url)
  	live_streams = JSON.parse(rsl)
  	live_streams.each do |st|
      if st['game_name'] != nil
        if st['game_name'] == 'Game'
          puts 'wtf!'
          puts st
        end
    		name = st['game_name']
        #find games whose name starts with 'the_game_name'
        re = Regexp.new(name, 'i')
        games = Game.where(name: re)
        #if none exist
        if games.count == 0
          #create one
      		the_game = Game.find_or_initialize_by(owned_name: name)
        else
          #select the first one
          the_game = games.first
          if the_game.owned_name == nil
            the_game.owned_name = name
          end
        end
        if the_game.name == nil
          the_game.name = name
        end
  	  	vs = the_game.viewstamps.find_or_initialize_by(timestamp_guid: timestamp_guid)
    		vs.viewers += st['live_viewers'].to_i
    		vs.owned_viewers += st['live_viewers'].to_i
    		vs.owned_channels += 1
    		vs.channels += 1
  	  	vs.save
        the_game.save
      end
  	end
	end
end
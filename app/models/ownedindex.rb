require 'net/http'
require "net/https"
require 'open-uri'
require 'json'
class Ownedindex
  include Mongoid::Document
  field :formula, :type => Hash
  field :version, :type => Integer
  field :raw_index, :type => Hash

  def self.make
		idx = Ownedindex.new
		idx.version = 1
		idx.save
		idx.download_latest
  end

  def get_id_view_search(search_term)
  	url = URI.escape('http://api.own3d.tv/rest/live/search.json?search='+search_term+'&limit=1')
  	response = JSON.parse(Net::HTTP.get(URI.parse(url)))
  	if response.length  > 0
	  	game_name = response[0]['game_name']
	  else
	  	game_name = nil
	  end
  end

  def download_latest
  	url = 'http://api.own3d.tv/rest/game/list.json'
  	response = JSON.parse(Net::HTTP.get(URI.parse(url)))
  	formula = {}
		response.each do |a_game|
			#puts a_game['game_name'] + ':' + a_game['game_id']
			game = Game.find_or_initialize_by(owned_name: a_game['game_name']) 
			game.owned_game_id = a_game['game_id']
			if a_game['game_name'] != nil and a_game['game_id'] != nil
				formula[a_game['game_name']] = a_game['game_id']
				game.owned_game_id = a_game['game_id']
			end
			#game.logo_small_url = a_game['game_logo_small']
			#game.owned_icon_url = a_game['game_icon']
			game.save
		end
		self.update_attribute(:formula, formula)
		self.update_attribute(:raw_index, response)
		puts self.formula.length
	end
end

class Ownedindex
  include Mongoid::Document
  field :name_to_id_map, :type => Hash
  field :version, :type => Integer
  field :raw_index, :type => Hash

  #a class method, not an instance method
  def self.make
  	idx = Ownedindex.find_or_initialize_by(version: 1)
  	url = 'http://api.own3d.tv/rest/game/list.json'
  	response = JSON.parse(Net::HTTP.get(url))
  	the_map = {}
		response.each do |a_game|
			game = Game.find_or_initialize_by(owned_name: a_game['game_name']) 
			game.owned_game_id = a_game['game_id']
			the_map[a_game['game_name']] = a_game['game_id']
			#game.logo_small_url = a_game['game_logo_small']
			#game.owned_icon_url = a_game['game_icon']
		end
		idx.update_attribute(:raw_index, response)
		idx.update_attribute(:name_to_id_map, the_map)
	end
end

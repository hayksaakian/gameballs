class Genre
  include Mongoid::Document
  has_and_belongs_to_many :games
  field :name, type: String
  field :giantbomb_id, type: String
  field :games_count, :type => Integer, :default => 0

  def self.populate
  	uri = 'http://api.giantbomb.com/genres/?format=json&field_list=id,name&api_key=569f949a9144b175988ed3179acde3139464a4eb'
      url = URI.parse(uri)
      rsl = Net::HTTP.get(url)
      response = JSON.parse(rsl)
      if(response['error'] == 'OK')
  		response['results'].each do |gnr|
  			the_genre = Genre.find_or_initialize_by(giantbomb_id: gnr['id'].to_s)
  			the_genre.name = gnr['name'].to_s
  			the_genre.save
  		end
  	end
  end

  def self.update_all_games_counts
    Genre.each do |gnr|
      gnr.update_attribute(:games_count, gnr.games.count)
    end
  end
end
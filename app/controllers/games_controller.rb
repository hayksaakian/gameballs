class GamesController < ApplicationController

  def genres
    genre_id = params[:genre_id]
    if genre_id != nil
      @genre = Genre.find_by(giantbomb_id: genre_id)
      @games = @genre.games
    else
      @games = Game.all
    end
    @games = @games.where(:current_viewers.gt => 0)
    @games = @games.where(:last_update.gte => 3.days.ago)
    @games = @games.order_by([:current_viewers , :desc]) 
    @genres = Genre.where(:games_count.ne => 0)  
    @genres = @genres.order_by([:games_count, :desc])
  end

  def update_counts
    #move to delayed method
    Game.update_counts
    respond_to do |format|
      format.html { redirect_to root_url, notice: 'Reloading viewer counts' }
    end
  end

  # GET /games
  # GET /games.json
  def index
    most_recent = Game.max(:last_update)
    @games = Game.where(:last_update.gte => 3.hours.ago)
    @games = @games.order_by([:current_viewers , :desc]).limit(25)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @games }
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show
    @game = Game.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @game }
    end
  end

  # GET /games/new
  # GET /games/new.json
  def new
    @game = Game.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @game }
    end
  end

  # GET /games/1/edit
  def edit
    @game = Game.find(params[:id])
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(params[:game])

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render json: @game, status: :created, location: @game }
      else
        format.html { render action: "new" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /games/1
  # PUT /games/1.json
  def update
    @game = Game.find(params[:id])

    respond_to do |format|
      if @game.update_attributes(params[:game])
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    respond_to do |format|
      format.html { redirect_to games_url }
      format.json { head :ok }
    end
  end
end

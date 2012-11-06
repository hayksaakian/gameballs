require 'csv'
require 'json'
class GamesController < ApplicationController
  include ActionView::Helpers::JavaScriptHelper

  def genres
    genre_id = params[:genre_id]
    if genre_id != nil
      @genre = Genre.find_by(giantbomb_id: genre_id)
      @games = @genre.games
    else
      @games = Game.all
    end
    @games = @games.where(:current_viewers.gt => 0)
    @games = @games.where(:last_update.gte => 1.day.ago)
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
    days_back = 3
    if params[:days_back]
      if params[:days_back].to_i > 0
        days_back = params[:days_back].to_i
      end
    else
      params[:days_back] = days_back.to_s
    end
    @games = Game.where(:last_update.gte => days_back.days.ago)
    @games = @games.order_by([:current_viewers, :desc])
    @games = @games.limit(25)
    gs = @games.limit(10)
    jsn = {}

    gs.each do |g|
      viewstamps = g.viewstamps.where(:timestamp.gte => days_back.days.ago)
      #viewstamps = viewstamps.order_by([:timestamp, :desc])
      gname = escape_javascript(g.name)
      viewstamps.each do |vs|
        ts = vs.timestamp.to_s
        if jsn[ts] == nil
          jsn[ts] = {}
        end
        if jsn[ts]['Date'] == nil
          jsn[ts]['Date'] = ts
        end
        jsn[ts][gname] = vs.viewers
      end
    end

    g_header = ['Date']
    gs.each do |g|
      g_header.push(escape_javascript(g.name))
    end
    g_rows = [g_header.join(',')]
    jsn.values.each do |jn|
      a_row = []
      g_header.each do |gh|
        if jn[gh] != nil
          a_row.push(jn[gh])
        else
          a_row.push(0)
        end
      end
      g_rows.push(escape_javascript(a_row.join(',')))
    end
    csv_string = g_rows.join('\n')
    @graph_data = csv_string

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @games }
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show
    if params[:id]
      @game = Game.find(params[:id])
    else
      s = CGI.unescape(params[:game_id])
      re = Regexp.new(s, 'i')
      puts s
      puts re
      #@game = Game.where(:name => re).first
      #if @game == nil
      @game = Game.first
      #end
    end
    days_back = 7
    if params[:days_back]
      if params[:days_back].to_i > 0
        days_back = params[:days_back].to_i
      end
    else
      params[:days_back] = days_back.to_s
    end
    jsn = {}
    @viewstamps = @game.viewstamps.where(:created_at.gte => days_back.days.ago)
    @viewstamps = @viewstamps.order_by([:created_at, :desc])
    jsn['Date'] = []
    @viewstamps.each do |vs|
      jsn['Date'].push(vs.created_at)
    end
    col = []
    @viewstamps.each do |vs|
      col.push(vs.viewers)
    end
    jsn[escape_javascript(@game.name)] = col
    g_names = jsn.keys.join(',')
    rows_arr = [g_names]
    counter = 0
    no_games = jsn.keys.length - 1
    #do this as many times as there are rows
    jsn['Date'].length.times do
      rs = []
      #do this for each column
      jsn.values.each do |cl|
        rs.push(cl[counter])
      end
      counter += 1
      rows_arr.push(rs.join(','))
    end
    @graph_data = rows_arr.join('\n')

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

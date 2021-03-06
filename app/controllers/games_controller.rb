class GamesController < ApplicationController
  before_filter :admin_required, :except => [:current, :show, :no_current_game, :player_status, :update_player_status]
  before_filter :load_game, :only => [:show, :edit, :update, :destroy, :player_status, :update_player_status]
  
  def index
    @games=Game.order('game_date desc').page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
    end
  end

  def current
    current_game=Game.current_game
    if current_game
      redirect_to game_path(current_game)
    else
      redirect_to({:action => 'no_current_game'})
    end
  end

  def new
    @game=Game.new(params[:game] || { :game_date => Date.today, :organizer_address => cookies[:email_address], :organizer => cookies[:organizer] })
    build_lists
    
    @players=Player.active.all
    @players.each{|pl| @game.game_players << GamePlayer.new(:player_id => pl.id, :current_state => 'no_response') }

    respond_to do |format|
      format.html
    end
  end
  
  def create
    @game=Game.new(params[:game])

    if @game.save
      flash[:notice] = 'Game add succeeded'
      redirect_to({:action => 'index'})
    else
      flash[:notice] = 'Game add failed'
      build_lists
      render :action => 'new'
    end
  end

  def edit
    build_lists true
    
    respond_to do |format|
      format.html
    end  
  end
  
  def update
    build_lists true
    @game.attributes=params[:game]

    respond_to do |format|
      if @game.save
        cookies[:email_address]={ :value => @game.organizer_address, :expires => 1.year.from_now }
        cookies[:organizer]={ :value => @game.organizer, :expires => 1.year.from_now }
        
        flash[:notice] = 'Game update succeeded'
        format.html { redirect_to games_path }
      else
        flash[:notice] = 'Game update failed'
        build_lists true
        format.html { render :action => 'edit' }
      end
    end
  end

  def player_status
    player = Player.find_by_email_address cookies[:email_address]
    @game_player = GamePlayer.where('game_id = ? AND player_id = ?', @game.id, player.try(:id)).first
    
    unless @game_player
      @game_player = GamePlayer.new(:game_id => @game.id)
      @game_player.current_state = :no_response      
    end

    @game_player.email_address = cookies[:email_address]    
	  @player_statuses = Player::PLAYER_STATUSES
  end
  
	def update_player_status
	  @player_statuses = Player::PLAYER_STATUSES
    @game_player = GamePlayer.new(params[:game_player])
    cookies[:email_address] = { :value => @game_player.email_address, :expires => 1.year.from_now }
    
    player = Player.where(:email_address => @game_player.email_address).first
    
    respond_to do |format|
      unless player
        flash[:alert]="Player not found by address"
        format.html { render :action => :player_status }
      else
        gp=GamePlayer.where(["game_id = ? AND player_id = ?", @game.id, player.id]).first
        gp.update_attribute(:current_state, params[:game_player][:current_state])

        format.html { redirect_to game_path(@game), :notice => "Confirmed #{player.name} as #{gp.current_state}" }
      end
    end
	end

  def destroy
    @game.destroy
    flash[:alert]="Successfully deleted #{@game.game_date}"
    redirect_to games_path
  end

  def show
  end

  protected
  def build_lists is_edit=false
    @player_statuses=Player::PLAYER_STATUSES
    @game_statuses=Game::GAME_STATUSES
    @game_statuses.reject{|s| s=="send_update"} unless is_edit
    @equipment=Equipment.all
  end
  
  private
  def load_game
    @game=Game.find(params[:id])
  end  
end

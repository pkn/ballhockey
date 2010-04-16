class GameController < ApplicationController
  def index
    @games=Game.paginate(:order => 'game_date desc', :page => params[:page])
    respond_to do |format|
      format.html
      format.iphone
    end
  end

  def current
    current_id = Game.current_game_id
    redirect_to({:action => 'view', :id => current_id})
  end

  def new
    @game=Game.new(params[:game])
    @game.game_status_id=1
    build_lists
    
    if request.post?
      params.each do |id, value|
        if(id.match(/^game_player/))
          @game.game_players.build(value)
        end
      end

      if @game.save
        flash[:notice] = 'Game add succeeded'
        redirect_to({:action => 'index'})

        # send notification
        @game.game_players.each do |gp|
          if(gp.player.has_email?)
            HockeyMailer.deliver_announce_game(@game, gp)
          end
        end
      else
        flash[:notice] = 'Game add failed'
        build_lists
        render :action => 'edit'
      end
    else
      #need to add the default players
      @players=Player.find(:all, :conditions => "active = 1")
      @players.each { |pl| @game.game_players << GamePlayer.new do |gp|
          gp.player_id=pl.id
          gp.equipment_id=5 #none
          gp.player_status_id=1 #no response
        end }

      #use the same form for editting
      render :action => 'edit'
    end
  end

  def edit
    @game=Game.find(params[:id])
    old_game_status_id=@game.game_status_id
    build_lists
    
    if request.post?
      @game.attributes=params[:game]
      @game.game_players.each do | gp |
        values=params["game_player_#{gp.player_id}"]
        gp.update_attributes(values)
      end
      if @game.save
        unless old_game_status_id == @game.game_status_id
          if @game.is_cancelled?
            HockeyMailer.deliver_cancel_game(@game)
          elsif @game.is_called?
            HockeyMailer.deliver_call_game(@game)
          end

        end

        flash[:notice] = 'Game update succeeded'
        redirect_to({:action => 'index'})
      else
        flash[:notice] = 'Game update failed'
      end
    end
  end

  def delete
    @game=Game.find(params[:id])
    @game.delete
    redirect_to :back
  end

  def view
    @game=Game.find(params[:id])
    @view_only=true
    render :action => 'edit'
#    respond_to do |format|
#      format.html
#      format.iphone
#    end
  end

  protected
  def build_lists
    @player_statuses=PlayerStatus.find(:all, :conditions => "description <> 'Maybe'")
    @game_statuses=GameStatus.find(:all)
    @equipment=Equipment.find(:all)
  end
end

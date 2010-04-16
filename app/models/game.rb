class Game < ActiveRecord::Base
  validates_uniqueness_of :game_date
  validates_presence_of :message
  validates_presence_of :organizer
  validates_presence_of :organizer_address
  has_many :game_players, :finder_sql => 'SELECT gp.* FROM game_players gp JOIN player_statuses sp ON (gp.player_status_id = sp.id) WHERE game_id=#{id} ORDER BY sp.description, equipment_id DESC'
  has_many :playing_players, :class_name => 'GamePlayer', :finder_sql => 'SELECT gp.* FROM game_players gp JOIN player_statuses sp ON (gp.player_status_id = sp.id) WHERE game_id=#{id} AND player_status_id > 2'
  has_many :game_goalies, :class_name => 'GameGoalie'
  accepts_nested_attributes_for :game_players
  belongs_to :game_status

  cattr_reader :per_page
  @@per_page = 10

  def number_playing
    playing_players.size
  end

  def all_players
    players=Array.new
    game_players.each do |p|
      if(p.player.has_email?)
        players << p.player.email_address
      end
    end
    players
  end

  def is_cancelled?
    return game_status_id==3
  end

  def is_called?
    return game_status_id==2
  end

  def was_played?
    return is_called?
  end

  def self.current_game_id
    game=Game.find_by_sql("SELECT * FROM games ORDER BY game_date DESC LIMIT 1")
    return game.id
  end

  def goalies
    goalie_names=""
    game_goalies.each do |g|
      if(goalie_names.length > 0) then
        goalie_names+=", "
      end
      goalie_names+=g.name
    end
    goalie_names
  end

  def full_message
    message + " (<a href='mailto:#{organizer_address}'>#{organizer}</a>)"
  end
end

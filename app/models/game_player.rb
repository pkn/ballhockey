class GamePlayer < ActiveRecord::Base
  include AASM
  
  belongs_to :game
  belongs_to :player
  belongs_to :equipment
  belongs_to :player_status
  attr_accessor :email_address
  scope :not_responded, where('game_players.current_state = ?', :no_response)
  scope :not_playing, where('game_players.current_state = ?', :out)
  scope :playing, where('game_players.current_state IN (?)', [:in, :late])
  scope :not_late, where('game_players.current_state = ?', :in)
  scope :goalie, where(:goalie => true)
  scope :played_games, joins(:game).merge(Game.played).playing

  aasm_column :current_state
  aasm_state :no_response
  aasm_state :out
  aasm_state :in
  aasm_state :late  
  aasm_initial_state :no_response
  
  def name_with_status
    name = player.try(:name)
    name += " (#{player_status.description})" if late?
    name += " (#{equipment.try(:description)})" if carrying_equipment?
    name
  end
  
  def friendly_state
    current_state.titleize
  end

  def playing?
    current_state=='late' || current_state=='in'
  end
  
  def not_playing?
    current_state=='out'
  end
  
  def no_response?
    current_state=='no_response'
  end

  def late?
    current_state=='late'
  end

  def carrying_equipment?
    !equipment.description[/None/i]
  end
  
  def sent?
    delivery_state=="sent"
  end
  
  def processed?
    delivery_state=="processed"
  end
  
  def deferred?
    delivery_state=="deferred"
  end
  
  def <=> other
    compare = current_state <=> other.current_state
    player.name <=> other.player.name if compare.zero?
    compare
  end  
end

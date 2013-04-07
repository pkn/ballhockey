class HockeyMailer < ActionMailer::Base
  include Resque::Mailer
  default :from => ENV['MAIL_SENDER']  
  
  def announce_game game 
    @game = game
    uniq_args({ :type => 'game', :id => game[:id], :state => 'announce' })
    mail base_options(game).merge({ :subject => "#{ENV['LEAGUE_NAME']} Ball Hockey Game for #{game.game_date}?"})
  end

  def update_game game
    @game = game
    uniq_args({ :type => 'game', :id => game[:id], :state => 'update' })
    mail base_options(game).merge({ :subject => "#{ENV['LEAGUE_NAME']} Ball Hockey Game Update for #{game.game_date}"})
  end

  def call_game game
    @game = game
    uniq_args({ :type => 'game', :id => game[:id], :state => 'call' })
    mail base_options(game).merge({ :subject => "#{ENV['LEAGUE_NAME']} Ball Hockey Game for #{game.game_date}: Game ON!"})
  end

  def cancel_game game
    @game = game
    uniq_args({ :type => 'game', :id => game[:id], :state => 'cancel' })
    mail base_options(game).merge({ :subject => "#{ENV['LEAGUE_NAME']} Ball Hockey Game for #{game.game_date}: Game Cancelled"})
  end
  
  def test to
    mail :to => to, :content_type => "text/html", :subject => 'Test Message'
  end
  
  private
  def base_options game
    { :reply_to => game.organizer_address, :content_type => "text/html", :to => game.all_players.map{|p| p.email_address} }
  end
end

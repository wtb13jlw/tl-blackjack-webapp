require 'rubygems'
require 'sinatra'

CARD_VALUE = {"ace"=>1, "2"=>2, "3"=>3, "4"=>4, "5"=>5, "6"=>6, "7"=>7, "8"=>8,
              "9"=>9, "10"=>10, "jack"=>10, "queen"=>10, "king"=>10, "Ace"=>11}
CARDS = %w[Ace 2 3 4 5 6 7 8 9 10 jack queen king]
SUITS = %w[clubs hearts spades diamonds]

set :sessions, true

helpers do

  def calc_hand(cards)
    total = 0
    cards.each { |face, suit| total += CARD_VALUE[face].to_i }
    
    aces = cards.select { |face, suit| face == 'Ace' }.count
    aces.times do
      if total > 21 
        total -= 10 if total > 21
      else 
        break 
      end
    end
    total
  end

  def get_image(card)
    card_face = (card[0].to_s).downcase
    suit = card[1]
    img = "<img src='/images/cards/#{suit}_#{card_face}.jpg' class='card_image'>"

  end

  def set_buttons
    @hit_button = "<input type='submit' value='Hit' class='btn btn-primary'/>"
    @stay_button = "<input type='submit' value='Stay' class='btn btn-info'/>"
    if calc_hand(session[:player_hand]).between?(3,11)
      @hit_button = "<input type='submit' value='Hit' class='btn btn-success'/>"
      @stay_button = "<input type='submit' value='Stay' class='btn btn-warning'/>"
    elsif calc_hand(session[:player_hand]) > 16 
      @hit_button = "<input type='submit' value='Hit' class='btn btn-warning'/>"
      @stay_button = "<input type='submit' value='Stay' class='btn btn-success'/>"
    end 
  end

  def tie_game(blackjack=false)
    if blackjack
      @tie_msg = "Both #{session[:player_name]} and Frank have BlackJack!  It's a Push!"
    else
      @tie_msg = "It's a Push!"
    end
    session[:player_wallet] += session[:cur_bet]
  end

  def easy_partial template
    erb template.to_sym, :layout => false
  end

end

before do
  @player_turn = false
  @dealer_turn = false
  @stay = false
  
end

get '/' do
  if session.include? :player_name
    redirect '/newgame'
  else
    redirect '/intro'
  end
end

get '/reset' do
  session.clear	
  redirect '/intro'
end

get '/intro' do
  erb :intro
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if session.include? :player_name
  elsif params[:player_name].length > 0
    session[:player_name] = params[:player_name].capitalize
    
  else
    redirect '/set_name'
  end
  session[:player_wallet] = 500
  redirect 'place_bet'
end

get '/place_bet' do
  unless session.include? :player_name
    redirect '/intro'
  else
    if session[:player_wallet] >= 2
      erb :place_bet
    else
      redirect 'game_over'
    end
  end
end

post '/place_bet' do
  if  session[:player_wallet] < 2
    redirect '/game_over'
  end

  if params[:cur_bet].length > 0
    session[:cur_bet] = params[:cur_bet].to_i
  else
    session[:cur_bet] = 2
  end
  
  if session[:cur_bet] > session[:player_wallet]
    @error = "You do not have that much to bet!  Try a lower amount."
    erb :place_bet
  else
    session[:player_wallet] -= session[:cur_bet]
    redirect '/newgame'
  end
end

get '/newgame' do
  session[:deck] = CARDS.product(SUITS)
  session[:deck].shuffle!

  session[:player_hand] = []
  session[:dealer_hand] = []

  2.times do
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop
  end
  @player_turn = true
  session[:initial_turn] = true
  set_buttons

  #session[:dealer_hand] = [['Ace', 'diamonds'], ['queen', 'hearts']]
  #session[:player_hand] = [['Ace', 'spades'], ['jack', 'spades']]

  if calc_hand(session[:player_hand]) == 21
    redirect '/winner'
  end

  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  if calc_hand(session[:player_hand]) < 22
    @player_turn = true
    set_buttons
  else
    redirect '/winner'
  end
  erb :game, layout: false
end

post '/stay' do
  if calc_hand(session[:dealer_hand]) == 21 && session[:dealer_hand].count == 2
    redirect '/winner'
  end

  @dealer_turn = true
  hv = calc_hand(session[:dealer_hand])
  if session[:initial_turn]
    session[:initial_turn] = false
  else
    if hv > 16 
      redirect '/winner'
    else
      session[:dealer_hand] << session[:deck].pop
      hv = calc_hand(session[:dealer_hand])
      if hv > 16 
        redirect '/winner'
      end
    end
  end

  erb :game, layout: false
end

get '/winner' do
  phv = calc_hand(session[:player_hand])
  dhv = calc_hand(session[:dealer_hand])
  @dealer_turn = true
  @stay = true
  @lose_msg = false
  @win_msg = false
  @tie_msg = false
    
  case
    when dhv == 21 && session[:dealer_hand].count == 2
      unless phv == 21 && session[:player_hand].count == 2
        @lose_msg = "Frank has BlackJack!  You Lose!"
        session[:player_wallet] -= session[:cur_bet]
      else
        tie_game(blackjack=true)
      end
    when phv == 21 && session[:player_hand].count == 2
      unless dhv == 21 && session[:dealer_hand].count == 2
        @win_msg = "#{session[:player_name]} has BlackJack!  #{session[:player_name]} Wins!"
        session[:player_wallet] += (session[:cur_bet] * 2.5)
      else
        tie_game
      end
    when dhv == phv
      tie_game
    when dhv > 21
      @win_msg = "Frank Busted!  #{session[:player_name]} Wins!"
      session[:player_wallet] += (session[:cur_bet] * 2)
    when phv > 21
      @lose_msg = "Sorry, You Busted!  The House Wins!"
    when dhv > phv
      @lose_msg = "Frank stays.  Your Hand was lower than Frank's Hand.  The House Wins!"
    when dhv < phv
      @win_msg = "#{session[:player_name]}'s Hand beat Frank's Hand. #{session[:player_name]} Wins!" 
      session[:player_wallet] += (session[:cur_bet] * 2)
    
  end
  session[:cur_bet] = 0
  
  erb :winner

end

get '/game_over' do
  if session.include? :player_name
    @pname = session[:player_name] 
    erb :game_over
  else
    erb :no_game
  end
end
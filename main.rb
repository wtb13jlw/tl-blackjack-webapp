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
  	src = "/images/cards/#{suit}_#{card_face}.jpg"
    img = '<img src="' + src + '">'
    
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
  if params[:player_name].length > 0
  	session[:player_name] = params[:player_name]
  	session[:player_wallet] = 500
    erb :place_bet
  else
  	redirect '/set_name'
  end
end

get '/place_bet' do
  erb :place_bet
end

post '/place_bet' do
  if params[:bet_amt].length > 0
    session[:bet_amt] = params[:bet_amt].to_i
  else
    session[:bet_amt] = 2
  end
  
  session[:player_wallet] -= session[:bet_amt] 
  redirect '/newgame'
  
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
  erb :game
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  if calc_hand(session[:player_hand]) < 22
    @player_turn = true
  else
    redirect '/winner'
  end
  erb :game
end

post '/stay' do
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

  erb :game
end

get '/winner' do
  phv = calc_hand(session[:player_hand])
  dhv = calc_hand(session[:dealer_hand])
  @dbust = false
  @pbust = false
  
  case
    when dhv == 21 && session[:dealer_hand].count == 2
      @error = "Frank has BlackJack!  You Lose!"
      #@dblackjack = true
    when phv == 21 && session[:player_hand].count == 2
      @success = "#{session[:player_name]} Wins!"
      #@pblackjack = true
    when dhv == phv
      @success = "It's a Tie!"
    when dhv > 21
      @success = "#{session[:player_name]} Wins!"
      @error = "Frank Busted!"
    when phv > 21
      #@success = "The House Wins!"
      @error = "Sorry, You Busted!  The House Wins!"
    when dhv > phv
      @error = "Your Hand was lower than Frank's Hand.  The House Wins!"
    when dhv < phv
      @success = "#{session[:player_name]} Wins!" 
    
    #end
  end
  
  erb :end_game

end

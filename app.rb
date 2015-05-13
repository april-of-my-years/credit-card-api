require 'sinatra'
require 'sinatra/param'
require_relative './model/credit_card'
require_relative './model/user'
require_relative './helpers/credit_card_helper'
require 'config_env'

# Old CLIs now on Web
class CreditCardAPI < Sinatra::Base
  configure :development, :test do
    require 'hirb'
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
    Hirb.enable
  end

  helpers Sinatra::Param

  include CreditCardHelper
  use Rack::Session::Cookie
  enable :logging

  before do
    @current_user = session[:user_id] ? User.find_by_id(session[:user_id]) : nil
  end

  get '/login' do
    haml :login
  end

  post '/login' do
    username = params[:username]
    password = params[:password]
    user = User.authenticate!(username, password)
    user ? login_user(user) : redirect('/login')
  end

  get '/logout' do
    session[:user_id] = nil
    redirect '/'
  end

  get '/register' do
    haml :register
  end

  post '/register' do
    logger.info("REGISTER")
    username = params[:username]
    email = params[:email]
    password = params[:password]
    password_confirm = params[:password_confirm]
    fullname = params[:fullname]
    address = params[:address]
    dob = params[:dob]
    begin
      if password == password_confirm
        new_user = User.new(username: username, email: email)
        new_user.password = password
        new_user.fullname = fullname
        new_user.address = address
        new_user.dob = dob
        new_user.save! ? login_user(new_user) : fail("Could not create new user")
      else
        fail "Passwords do not match"
      end
    rescue => e
      logger.error(e)
      redirect '/register'
    end
  end

  get '/' do
    haml :index
  end

  get '/api/v1/credit_card/?' do
    'Right now, the professor says to just let you validate credit
    card numbers and you can do that with: <br />
    GET /api/v1/credit_card/validate?card_number=[your card number]'
  end

  get '/api/v1/credit_card/validate/?' do
    param :card_number, Integer
    halt 400 unless params[:card_number]

    card = CreditCard.new(number: "#{params[:card_number]}")

    { "card": card.number,
      "validated": card.validate_checksum
    }.to_json
  end

  post '/api/v1/credit_card/?' do
    details_json = JSON.parse(request.body.read)

    begin
      card = CreditCard.new(number: "#{details_json['number']}",
                            expiration_date:
                            "#{details_json['expiration_date']}",
                            credit_network: "#{details_json['credit_network']}",
                            owner: "#{details_json['owner']}")
      halt 400 unless card.validate_checksum
      status 201 if card.save
    rescue
      halt 410
    end
  end

  get '/api/v1/credit_card/all/?' do
    begin
      CreditCard.all.map(&:to_s)
    rescue
      halt 500
    end
  end
end

require 'sinatra'
require 'sinatra/param'
require_relative './model/credit_card'
require_relative './model/user'
require 'config_env'
require 'rack-flash'
require_relative './helpers/creditcardapi_helper'

# Old CLIs now on Web
class CreditCardAPI < Sinatra::Base
  include CreditCardHelper
  enable :logging
  
  configure :development, :test do
    require 'hirb'
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
    Hirb.enable
  end

  helpers Sinatra::Param

  configure do
    use Rack::Session::Cookie, secret: ENV['MSG_KEY']
    use Rack::Flash, :sweep => true
  end

  before do
    @current_user=find_user_by_token(session[:auth_token])
  end

  #before do
  #  @current_user = session[:user_id] ? User.find_by_id(session[:user_id]) : nil
  #end

  get '/login' do
    haml :login
  end

  post '/login' do
    username = params[:username]
    password = params[:password]
    user = User.authenticate!(username, password)
   if user
      login_user(user)
      redirect '/'
    else
      flash[:error] = "We could not find your account with those credentials"
      redirect '/login'
    end
  end

  get '/logout' do
     session[:auth_token] = nil
    flash[:notice] = "You have logged out"
    redirect '/'
  end

  get '/register' do
     if token = params[:token]
      begin
        create_user_with_encrypted_token(token)
        flash[:notice] = "Welcome! Your account has been successfully created."
      rescue
        flash[:error] = "Your account could not be created. Your link is either expired or invalid."
      end
      redirect '/'
    else
      haml :register
    end
  end

  post '/register' do
   registration = Registration.new(params)

    if (registration.complete?) && (params[:password] == params[:password_confirm])
      begin
        email_registration_verification(registration)
        flash[:notice] = "A verification link has been sent to you. Please check your email!"
        redirect '/'
      rescue => e
        logger.error "FAIL EMAIL: #{e}"
        flash[:error] = "Could not send registration verification: check email address"
        redirect '/register'
      end
    else
      flash[:error] = "Please fill in all the fields and make sure passwords match"
      redirect '/register'
    end
  end


  get '/' do
    haml :index
  end

  get '/api/v1/credit_card/?' do
    haml :services
  end

  get '/api/v1/credit_card/validate/?' do
    logger.info('VALIDATE')
    begin
      param :card_number, Integer
      fail('Pass a card number') unless params[:card_number]
      card = CreditCard.new(number: "#{params[:card_number]}")
      haml :validated, locals: { number: card.number,
                                 validate_checksum: card.validate_checksum }
    rescue => e
      logger.error(e)
      redirect '/api/v1/credit_card/'
    end

    # { "card": card.number,
    #   "validated": card.validate_checksum
    # }.to_json
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
    haml :all, locals: { result: CreditCard.all.map(&:to_s) }
  end
end

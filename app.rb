require 'sinatra'
require 'sinatra/param'
require_relative './model/credit_card'
require 'config_env'

# Old CLIs now on Web
class CreditCardAPI < Sinatra::Base
  configure :development, :test do
    require 'hirb'
    Hirb.enable
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
  end
  helpers Sinatra::Param
  get '/' do
    'The Credit Card API is running at <a href="/api/v1/credit_card/">
    /api/v1/credit_card/</a>'
  end

  get '/api/v1/credit_card/?' do
    'Right now, the professor says to just let you validate credit
    card numbers and you can do that with: <br />
    GET /api/v1/credit_card/validate?card_number=[your card number]'
  end

  get '/api/v1/credit_card/validate/?' do
    param :card_number, Integer
    card_number = params[:card_number]
    halt 400 unless card_number
    card = CreditCard.new(number: "#{card_number}", expiration_date: "expiration_date",
                            credit_network: "credit_network", owner: "owner")
    { "card": "#{card_number}",
      "validated": card.validate_checksum
    }.to_json

  end

  post '/api/v1/credit_card/?' do
    details_json = JSON.parse(request.body.read)

    begin
      number = details_json['number']
      owner = details_json['owner']
      credit_network = details_json['credit_network']
      expiration_date = details_json['expiration_date']
      card = CreditCard.new(number: "#{number}", expiration_date: "#{expiration_date}",
                            credit_network: "#{credit_network}", owner: "#{owner}")
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

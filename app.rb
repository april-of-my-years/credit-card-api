require 'sinatra'
require 'sinatra/param'
require_relative './model/credit_card'

# Old CLIs now on Web
class CreditCardAPI < Sinatra::Base
  register Sinatra::ActiveRecordExtension
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

    card = CreditCard.new(card_number, nil, nil, nil)
    { "card": "#{card_number}",
      "validated": card.validate_checksum
    }.to_json
  end

  post '/api/v1/credit_card/?' do
    request_json = request.body.read
    req = JSON.parse(request_json)
    begin
      card_number = req['number']
      card_exp_date = req['expiration_date']
      card_owner = req['owner']
      card_credit_network = req['credit_network']
        
      card = CreditCard.new(:number => card_number,
                            :expiration_date => card_exp_date,
  		          :owner => card_owner,
  		          :credit_network => card_credit_network)

      halt 400 unless card.validate_checksum

      card.save
  
      return 201
  
    rescue
      halt 410, 'You need to check for you parameters'
    end
  end

  get '/api/v1/credit_card/data/?' do
    begin
      CreditCard.all.map do |card|
        {
        :number => card.number,
        :expiration_date => card.expiration_date,
        :owner => card.owner,
        :credit_network => card.credit_network
        }
      end.to_json

    rescue
      return 500
    end
  end
end

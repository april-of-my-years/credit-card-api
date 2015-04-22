require 'sinatra'
require 'sinatra/param'
require 'sinatra/activerecord'
require_relative './model/credit_card'


set :database,{adapter: "sqlite3", database:"db/dev.db"}
# Old CLIs now on Web
class CreditCardAPI < Sinatra::Base
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
  post '/api/v1/credit_card' do
    number=nil
    expiration_date=nil
    owner=nil
    credit_network=nil
  begin
    request_json=request.body.read
    req=JSON.parse(request_json)
   
    
    number=req['number']

    expiration_date=req['expiration_date']

    owner=req['owner']

    credit_network=req['credit_network']
    
    #card_num=CreditCard.new(credit_card: credit_card.to_json,owner: owner.to_json,expiration_date: expiration_date.to_json,credit_network: credit_network.to_json)
    card_num=CreditCard.new(number: number,owner: owner,expiration_date: expiration_date,credit_network: credit_network)
    halt 400 unless card_num.validate_checksum
    card_num.save
      return 201
    rescue
    halt 410 
    end
  end


  get '/api/v1/credit_card/db_all' do
    begin
      credit=CreditCard.all.map do
        {number:credit.number,owner: credit.owner, expiration_date: credit.expiration_date, credit_network: credit.credit_network }.to_json
      end
    rescue
    halt 500
    end
  end
end

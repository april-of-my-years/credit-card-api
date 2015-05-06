require_relative 'spec_helper.rb'

  describe 'CreditCard API' do 
  	describe 'Getting the root' do
  		it 'should successfully return ok' do
  			get '/'
  			last_response.status.must_equal 200
  		end
  	end

  	describe 'Getting card_card' do
  		before do
  			CreditCard.delete_all
  		end

   	 	cards=[{number:'5192234226081802',valid: true}]

   	 	it 'should test card_number valid' do
  		 cards.each do |card|
  		
  		get "/api/v1/credit_card/validate?card_number=#{card[:number]}"
  	  	last_response.status.must_equal 200
  		results=JSON.parse(last_response.body)
  		results['validated'].must_equal card[:valid]
     	 end
        end

        cards=[{number: '4539075978041247',valid: false}]
        it 'should test card_number invalid' do
        	cards.each do |card|
        get  "/api/v1/credit_card/validate?card_number=#{card[:number]}"
        last_response.status.must_equal 200
        results=JSON.parse(last_response.body)
        results['validated'].must_equal card[:valid]
    		end
    	end
    end

    describe 'testing post' do
  		before do
  			CreditCard.delete_all
  		end
  		describe 'get into post for valid' do
 		cards=[{number:'5192234226081802',owner:'Cheng-Yu Hsu',expiration_date: '2017-04-19',credit_network:'Visa'}]
          it 'should test card valid' do
          	cards.each do |card|
            req_header = { 'CONTENT_TYPE' => 'application/json' }
            req_body = {expiration_date: '2017-04-19', owner: 'Cheng-Yu Hsu',
                         number: "#{card[:number]}", credit_network: "#{card[:credit_network]}" }
            post '/api/v1/credit_card/?', req_body.to_json, req_header
            last_response.status.must_equal 201
          end
        end
    end
    describe 'get into post for invalid' do
        cards=[{number:'4539075978041247',owner:'Karen Lai',expiration_date: '2020-06-07',credit_network:'Visa'}]
          it 'should test card invalid' do
          	cards.each do |card|
          	req_header = { 'CONTENT_TYPE' => 'application/json' }
            req_body = {expiration_date: '2020-06-07', owner: 'Karen Lai',
                        number: "#{card[:number]}", credit_network: "#{card[:credit_network]}" }
            post '/api/v1/credit_card', req_body.to_json, req_header
            last_response.status.must_equal 400
     		end
		  end
		end
	end
end
    
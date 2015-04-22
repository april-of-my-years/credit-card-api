class CreateCreditCards < ActiveRecord::Migration
  def change
  	create_table :credit_cards do |item|
  		item.string :number
  		item.string :owner
  		item.string :expiration_date
  		item.string :credit_network

       end
    end
end
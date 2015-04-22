class CreateCreditCards < ActiveRecord::Migration
  def change
  	create_table :credit_cards do |card|
		card.string :number
		card.string :expiration_date
		card.string :owner
		card.string :credit_network
	end
  end
end

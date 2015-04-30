class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |cc|
      cc.string :encrypted_number, :expiration_date, :owner, :credit_network, :nonce
    end
  end
end

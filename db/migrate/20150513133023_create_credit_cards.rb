class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |cc|
      cc.string :expiration_date, :owner, :credit_network, :nonce_64
      cc.text :encrypted_number
    end
  end
end

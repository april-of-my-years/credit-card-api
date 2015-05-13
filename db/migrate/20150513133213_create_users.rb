class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |cc|
      cc.string :username, :email, :hashed_password, :encrypted_fullname, :encrypted_address, :encrypted_dob, :salt, :nonce_64
    end
  end
end

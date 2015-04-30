require 'sinatra/activerecord'
require_relative '../environments'
require_relative '../lib/luhn_validator.rb'
require 'json'
require 'openssl'
require 'forwardable'
require 'rbnacl/libsodium'
require 'Base64'

# Credit Card class, the basis for humanity
class CreditCard < ActiveRecord::Base
  include LuhnValidator
  extend Forwardable
  
  def key
    ENV['DB_KEY'].dup.force_encoding Encoding::BINARY
  end
  
  def number=(raw_num)
    en_key=RbNaCl::SecretBox.new(key)
    self.nonce=RbNaCl::Random.random_bytes(en_key.nonce_bytes)
    self.encrypted_number=Base64.encode64(en_key.encrypt(self.nonce,raw_num))
    self.nonce = Base64.encode64(self.nonce)
  end
  
  def number
   en_key=RbNaCl::SecretBox.new(key)
   en_key.decrypt(Base64.decode64(self.nonce),Base64.decode64(self.encrypted_number))
  end
  # instance variables with automatic getter/setter methods
  # attr_accessor :number, :expiration_date, :owner, :credit_network

  # def initialize(number, expiration_date, owner, credit_network)
  #   @number = number
  #   @expiration_date = expiration_date
  #   @owner = owner
  #   @credit_network = credit_network
  # end

  # returns json string
  # def to_json
  #   {
  #     number: @number, expiration_date: @expiration_date, owner: @owner,
  #     credit_number: @credit_number
  #   }.to_json
  # end

  # returns all card information as single string
  def to_s
    {
      number: number, owner: owner, expiration_date: expiration_date,
      credit_network: credit_network
    }.to_json
  end

  # return a new CreditCard object given a serialized (JSON) representation
  def self.from_s(card_s)
    new(*(JSON.parse(card_s).values))
  end

  # return a hash of the serialized credit card object
  delegate hash: :to_s

  # return a cryptographically secure hash
  def hash_secure
    sha256 = OpenSSL::Digest::SHA256.new
    sha256.digest(to_s).unpack('H*')[0]
  end
end

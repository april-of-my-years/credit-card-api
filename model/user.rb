require 'sinatra/activerecord'
require 'protected_attributes'
require_relative '../environments'
require 'rbnacl/libsodium'
require 'base64'

class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, format: /@/
  validates :hashed_password, presence: true
  validates :encrypted_fullname, presence: true
  validates :encrypted_address, presence: true
  validates :encrypted_dob, presence: true

  attr_accessible :username, :email

  def key
    Base64.urlsafe_decode64(ENV['DB_KEY'])
  end

  def enc
    enc = RbNaCl::SecretBox.new(key)
    @nonce ||= RbNaCl::Random.random_bytes(enc.nonce_bytes)
    self.nonce_64 = Base64.urlsafe_encode64(@nonce)
    enc
  end

  def dec
    dec = RbNaCl::SecretBox.new(key)
  end

  def password=(new_password)
    salt = RbNaCl::Random.random_bytes(RbNaCl::PasswordHash::SCrypt::SALTBYTES)
    digest = self.class.hash_password(salt, new_password)
    self.salt = Base64.urlsafe_encode64(salt)
    self.hashed_password = Base64.urlsafe_encode64(digest)
  end

  def self.authenticate!(username, login_password)
    user = User.find_by_username(username)
    user && user.password_matches?(login_password) ? user : nil
  end

  def password_matches?(try_password)
    salt = Base64.urlsafe_decode64(self.salt)
    attempted_password = self.class.hash_password(salt, try_password)
    hashed_password == Base64.urlsafe_encode64(attempted_password)
  end

  def self.hash_password(salt, pwd)
    opslimit = 2**20
    memlimit = 2**24
    digest_size = 64
    RbNaCl::PasswordHash.scrypt(pwd, salt, opslimit, memlimit, digest_size)
  end

  def fullname=(params)
    self.encrypted_fullname = Base64.urlsafe_encode64(enc.encrypt(@nonce, "#{params}"))
  end

  def fullname
    dec.decrypt(Base64.urlsafe_decode64(self.nonce_64), Base64.urlsafe_decode64(self.encrypted_fullname))
  end

  def address=(params)
    self.encrypted_address = Base64.urlsafe_encode64(enc.encrypt(@nonce, "#{params}"))
  end

  def address
    dec.decrypt(Base64.urlsafe_decode64(self.nonce_64), Base64.urlsafe_decode64(self.encrypted_address))
  end

  def dob=(params)
    self.encrypted_dob = Base64.urlsafe_encode64(enc.encrypt(@nonce, "#{params}"))
  end

  def dob
    dec.decrypt(Base64.urlsafe_decode64(self.nonce_64), Base64.urlsafe_decode64(self.encrypted_dob))
  end
end

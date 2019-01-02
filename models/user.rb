require 'bcrypt'
class User < Sequel::Model
  include BCrypt
  one_to_many :owned_baby_lists, :class => :BabyList
  many_to_many :baby_lists
  
  def self.create_user(email, password)
    #Does a user already exist with this email?
    if (u = self.where(:email => email).first)
      raise("Email is already taken") if u.active
      u.active = true
      u.set_password(password)
    else
      u = self.new
      u.email = email
      u.set_password(password)
    end
    u.save
    u
  end

  def self.authenticate(email, password)
    return nil unless u = self.where(:email => email, :active => true).first
    u.correct_password?(password) ? u : nil
  end

  def set_password(password)
    self.hashed_password = Password.create(password)
  end

  def correct_password?(password)
    Password.new(self.hashed_password) == password
  end
end
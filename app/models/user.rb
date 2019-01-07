require 'bcrypt'
class User < Sequel::Model
  include BCrypt
  one_to_many :owned_baby_lists, :class => :BabyList, :order => :name
  many_to_many :baby_lists
  
  def self.create_user(email, password)
    #Does a user already exist with this email?
    if (u = self.where(:email => email).first)
      raise("Email is already taken") if u.active
      u.set_password(password)
    else
      u = self.new
      u.email = email
      u.set_password(password)
    end
    u.active = true
    u.save
    u
  end

  #Will create a stub if needed
  def self.get_user(email)
    self[:email => email] || self.create(:email => email, :active => false)
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

  def my_lists
    (self.owned_baby_lists + self.baby_lists).uniq.sort_by(&:name)
  end

  def self.admin_user
    User[:email => "admin@admin.com"] || User.create_user("admin@admin.com", rand(99999999999999999).to_s)
  end
end
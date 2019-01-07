class BabyName < Sequel::Model
  one_to_many :baby_ratings
  many_to_many :baby_lists, :join_table => :baby_ratings
end
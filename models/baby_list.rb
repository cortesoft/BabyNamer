class BabyList < Sequel::Model
  one_to_many :baby_ratings
  many_to_many :baby_names, :join_table => :baby_ratings
end
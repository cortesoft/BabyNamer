class Vote < Sequel::Model
  many_to_one :baby_rating
  many_to_one :user
  many_to_one :name_1, :class => :BabyName
  many_to_one :name_2, :class => :BabyName
end
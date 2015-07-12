class BabyRating < Sequel::Model
  many_to_one :baby_name
  many_to_one :baby_list
  
  def name
    self.baby_name.name
  end
end
class BabyList < Sequel::Model
  one_to_many :baby_ratings
  many_to_many :baby_names, :join_table => :baby_ratings

  #creates from an array of names
  def self.create_from_list(list_name, name_list, boy_names = false)
    raise "A list with that name already exists!" if self.where(:name => list_name).count > 0
    c = self.create(:name => list_name, :boys => boy_names)
    new_names = name_list.dup
    #Find the names already created
    BabyName.where(:name => name_list, :boy => boy_names).all.each do |bn|
      c.add_baby_rating(:baby_name => bn)
      new_names.delete(bn.name)
    end
    #create all the new names
    new_names.each do |name|
      bn = BabyName.create(:name => name, :boy => boy_names)
      c.add_baby_rating(:baby_name => bn)
    end
    c
  end

  def duplicate_list(new_name)
    raise "A list with that name already exists!" if self.class.where(:name => new_name).count > 0
    c = self.class.create(:name => new_name, :boys => self.boys)
    self.baby_names.each do |bn|
      c.add_baby_rating(:baby_name => bn)
    end
    c
  end

  #Returns two names to choose between
  def two_names
    name1 = random_name
    if rand(100) > 75
      name2 = random_name
      name2 = random_name while name1 == name2
    else
      possibles = closest_rank_to(name1, 20)
      name2 = possibles[rand(possibles.size)]
    end
    [name1.name, name2.name]
  end
 
  def update_tie(name1, name2)
    name1_rating = rating_for(name1)
    update_rank(name1, rating_for(name2), 0.5)
    update_rank(name2, name1_rating, 0.5)
  end

  def update_winner(name1, name2)
    name1_rating = rating_for(name1)
    update_rank(name1, rating_for(name2), 1)
    update_rank(name2, name1_rating, 0)
  end

  def random_name
    self.baby_names[rand(self.baby_names.size)]
  end
  
  def k_factor(name)
    count_for(name) > 10 ? 10 : 30
  end
  
  def expected_score_for(my_rate, opp_rate)
    1.0 / (1 + 10 ** ((opp_rate - my_rate)/400.0))
  end
  
  def update_rank(name, opp_rate, result)
    my_rating = rating_for(name)
    new_rank = my_rating + k_factor(name) * (result - expected_score_for(my_rating, opp_rate))
    set_rating(name, new_rank)
    new_rank
  end
  
  def closest_rank_to(name, num_to_return)
    ro = rating_obj(name)
    self.baby_ratings_dataset.exclude(:id => ro.id).eager(:baby_name).
      order(Sequel.lit("ABS(rating - #{ro.rating})")).limit(num_to_return).all
  end
 
  #Helpers
  #Pass either a name object or a name, returns the object
  def name_obj(name)
    name = name.baby_name if name.is_a?(BabyRating)
    name.is_a?(String) ? self.baby_names_dataset.where(:name => name).first : name
  end

  def rating_obj(name)
    self.baby_ratings_dataset.where(:baby_name_id => name_obj(name).id).first
  end

  def count_for(name)
    rating_obj(name).count
  end
  
  def rating_for(name)
    rating_obj(name).rating
  end
  
  def set_rating(name, rating, count_plus = 1)
    rn = rating_obj(name)
    rn.rating = rating
    rn.count += count_plus
    rn.save
  end
end
class BabyList < Sequel::Model
  one_to_many :baby_ratings
  many_to_many :baby_names, :join_table => :baby_ratings
  many_to_many :voters, :class => :User, :join_table => :baby_lists_users, :left_key => :baby_list_id, :right_key => :user_id
  one_to_many :votes
  many_to_one :user

  def delete_names(names)
    baby_names = self.baby_names_dataset.where(:name => names).all
    self.baby_ratings_dataset.where(:baby_name => baby_names).delete
  end

  def can_vote?(other_user)
    self.user_id == other_user.id || self.voters.include?(other_user)
  end

  def add_as_voter(email)
    u = User.get_user(email)
    return "You can't invite yourself" if u.id == self.user_id
    return "You have already invited #{email}" if self.voters.include?(u)
    self.add_voter(u)
    "Invited #{email} to be a voter on this list"
  end
  #creates from an array of names
  def self.create_from_list(user, list_name, name_list, cloneable = false)
    boy_names = false # We have not implemented this yet
    c = self.create(
      :name => self.get_name(list_name),
      :boys => boy_names,
      :user => user,
      :cloneable => cloneable
    )
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

  def self.get_name(wanted_name)
    count = 1
    actual_name = wanted_name
    while self[:name => actual_name]
      actual_name = wanted_name + "_#{count}"
    end
    actual_name
  end

  def duplicate_list(new_name, new_user)
    c = self.class.create(
      :name => self.class.get_name(new_name),
      :boys => self.boys,
      :user => new_user,
      :cloneable => false
    )
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
 
  def update_tie(name1, name2, voter)
    name1_rating = rating_for(name1)
    update_rank(name1, rating_for(name2), 0.5)
    update_rank(name2, name1_rating, 0.5)
    record_vote(name1, name2, voter, 0)
  end

  def update_winner(name1, name2, voter)
    name1_rating = rating_for(name1)
    update_rank(name1, rating_for(name2), 1)
    update_rank(name2, name1_rating, 0)
    winner = name_obj(name1)
    record_vote(winner, name2, voter, winner.id)
  end

  def record_vote(name1, name2, voter, winner)
    self.add_vote(
      :name_1_id => name_obj(name1).id,
      :name_2_id => name_obj(name2).id,
      :user => voter,
      :chosen_name => winner
    )
  end

  def random_name
    if rand(100) > 90
      choices = self.baby_ratings_dataset.eager(:baby_name).
        reverse(:rating).limit(10).all.map(&:baby_name)
      choices[rand(choices.size)]
    else
      self.baby_names[rand(self.baby_names.size)]
    end
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

  def self.create_defaults
    u = User.admin_user
    ["Boys", "Girls"].each do |g|
      all_names = nil
      [50, 100, 500, 1000, 2000, 5000, 10000].each do |n|
        name = "Top #{n} #{g} Names"
        unless self[:name => name]
          puts "Creating #{name} list"
          all_names ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), "../default_names", g))).split("\n")
          self.create_from_list(u, name, all_names[0,n], true)
        end
      end
      name = "All #{g} Names"
      unless self[:name => name]
        puts "Creating #{name} list"
        all_names ||= File.read(File.expand_path(File.join(File.dirname(__FILE__), "../default_names", g))).split("\n")
        self.create_from_list(u, name, all_names, true)
      end
    end
  end
end
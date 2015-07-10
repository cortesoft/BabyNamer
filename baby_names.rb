require 'json'

unless (name_file = ARGV[0]) && File.exists?(name_file)
  puts "Name file?"
  name_file = gets.chomp
  raise "No such file!" unless File.exists?(name_file)
end

@names = File.read(name_file).split("\n")

puts "Use the top x out of #{@names.size} names?"
num = gets.chomp.to_i

if num < 0 or num > @names.size
  raise "invalid selection!"
end

@names = @names[0, num]

unless (data_file = ARGV[1])
  data_file = "#{name_file}_data.json"
end

@data = File.exists?(data_file) ? JSON.parse(File.read(data_file)) : {}

def random_name
  @names[rand(@names.size)]
end

def data_for(name)
  @data[name] ||= {"rating" => 1500, "count" => 0}
end

def rating_for(name)
  data_for(name)["rating"]
end

def count_for(name)
  data_for(name)["count"]
end

def set_rating(name, rating)
  data_for(name)["rating"] = rating
end

def add_count(name, num = 1)
  data_for(name)["count"] += num
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
  add_count(name)
  new_rank
end

while true
  name1 = random_name
  name2 = random_name
  next if name1 == name2
  puts "\n\n1. #{name1}\n2. #{name2}\nWhich name is better? (3 for tie, x to stop the loop)"
  res = gets.chomp
  break if res == "x"
  if res == "1"
    score1 = 1
    score2 = 0
  elsif res == "2"
    score1 = 0
    score2 = 1
  elsif res == "3"
    score1 = 0.5
    score2 = 0.5
  else
    puts "Unknown choice #{res}!"
    next
  end
  name1_rating = rating_for(name1) #so we use the old score before updating
  update_rank(name1, rating_for(name2), score1)
  update_rank(name2, name1_rating, score2)
end

#save the data
File.write(data_file, @data.to_json)

puts "Current top scores:"

place = 1
@data.to_a.sort_by {|name, data| data['rating'] }.reverse.each do |name, data|
  puts "#{place}. #{name} - #{data['rating'].to_i} (#{data['count']})"
  place += 1
end

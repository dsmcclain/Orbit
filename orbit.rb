Dir["./Classes/*"].each {|file| require file}
require 'csv'

def welcome_to_orbit
  print_welcome_screen
  game = generate_game
  print_introduction
  game.start_game
end

def print_welcome_screen
  title = CSV.read("title.txt").each {|line| puts line[0]}
  puts "\n"*4
  puts "How many astronauts will be orbiting?"
  print ">>"
end

def generate_game
  number_of_players = gets.chomp.to_i
  game = Game.new(generate_astronauts(number_of_players), Turn.new(Map.new))
end

def generate_astronauts(astronauts)
  astronaut_array = []
  astronauts.times do |x|
    puts "Enter Astronaut #{x+1}'s name: "
    name = gets.chomp
    astronaut_array << Astronaut.new(name, Collection.new)
  end
  return astronaut_array
end

def print_introduction
  puts "You have secured orbit around an unknown planet."
  sleep(2)
  puts "Your goal is to discover as much as you can while staying alive."
  sleep(2)
  puts "There are no guarantees."
  sleep(2)
end

welcome_to_orbit

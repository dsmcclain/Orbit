require 'csv'

class Game
  attr_accessor :astronauts, :map, :current_astronaut, :day

  def initialize(astronauts, map)
    @astronauts = astronauts
    @map = map
    @current_astronaut
    @day = 0
  end

  def start_game
    print_introduction
    while day < 10
      new_turn
    end
    finish_game
  end

  def new_turn
    astronauts.each {|astronaut| 
      self.current_astronaut = astronaut
      puts "\n#{current_astronaut.name}'s turn!"
      captains_log
      astronaut.start_turn(self)}
    self.day += 1
  end

  def lookup_location
    location = current_astronaut.attributes[:location]
    sector = map[location] || (raise StandardError, "location does not exist in map")
    sector.arrive_at_sector(self)
  end

  def report_on_location(sector)
    puts "You have arrived at sector #{sector.location}."
    sector.claim_territory(self)
    puts "At this sector there is #{sector.event}"
  end

  def finish_game
    puts "Game Over."
  end

  private

    def print_introduction
      puts "You have secured orbit around an unknown planet."
      sleep(2)
      puts "Your goal is to discover as much as you can while staying alive."
      sleep(2)
      puts "There are no guarantees."
      sleep(2)
    end

    def captains_log
      puts "\n>> CAPTAIN'S LOG >>>> I have been orbiting for #{day} " + (day == 1 ? "day." : "days.")
      print ">> "
      if day < 3
        puts $early_log[day]
      elsif current_astronaut.attributes[:morale] > 75
        entry = rand(0..4)
        puts $optimist_log[entry]
      else
        entry = rand(0..4)
        puts $pessimist_log[entry]
      end
    end
end

class Astronaut
  attr_accessor :name, :attributes, :items, :turn_over

  def initialize(name)
    @name = name
    @attributes = {
      :location => 0,
      :morale => 100,
      :fuel => 50,
      :speed => 1
    }
    @items = []
    @turn_over = false
  end

  def start_turn(game)
    self.turn_over = false
    until turn_over
      user_prompt(game)
    end
  end

  def user_prompt(game)
    puts "How do you proceed? (enter 'ls' to list possible commands)"
    print ">>"
    input = gets.chomp.downcase
    case input
    when "d"
      move_ship
      update_fuel
      game.lookup_location
      self.turn_over = true
    when "c"
      list_items
    when "s"
      show_statistics
    when "i"
      use_item(game)
    when "ls"
      list_options
    else
      puts "That command is not executable"
    end
  end

  def receive_event(event)
    puts 'here'
    var = event.attribute.to_sym
    self.attributes[var] += event.degree
    check_location
    puts "#{self.name}'s #{event.attribute} is now #{self.attributes[var]}"
  end

  def retrieve_item(item)
    self.items << item
    list_items
  end

  private

    def calculate_distance
      rand(0..5) + self.attributes[:speed]
    end

    def move_ship
      self.attributes[:location] += calculate_distance
      puts "Driving..."
      sleep(1)
      check_location
    end

    def check_location
      if attributes[:location] < 1
        self.attributes[:location] += 10
      elsif attributes[:location] > 10
        pass_go
      end
    end

    def pass_go
      self.attributes[:location] -= 10
      complete_orbit
    end

    def complete_orbit
      self.attributes[:morale] += 10
      puts "You have completed a full orbit! The sensation of progress boosts your morale to #{attributes[:morale]}."
    end

    def update_fuel
      self.attributes[:fuel] -= 2
    end

    def use_item(game)
      puts "Which item will you use?"
      list_items
      puts "0: cancel"
      print ">>"
      input = gets.to_i - 1
      if (0..items.size).cover? input
        chosen_item = items[input]
        print chosen_item
        recipients = chosen_item.scope
        recipients.each {|recipient| recipient.receive_event(chosen_item) }
      else
        user_prompt(game)
      end
    end

    def list_items
      puts "Your collection holds: "
      self.items.each_with_index {|item, i| puts "\t" + (i + 1).to_s + ": " + item[:name] + "\n"}
    end

    def list_options
      puts %Q{ Possible Commands:
        (d) - Drive ship
        (c) - List collection
        (s) - Ship statistics
        (i) - Use item
      }
    end

    def show_statistics
      puts %Q{ Ship Statistics
        Current Sector is: #{attributes[:location]}
        Speed is         : #{attributes[:speed]}
        Fuel is          : #{attributes[:fuel]}
        Morale is        : #{attributes[:morale]}
        Collection holds : #{items.size} items
      }
    end
end

class Sector 
  attr_accessor :location, :owner, :event, :item

  def initialize(location)
    @location = location
    @owner
    @event
    @item
  end

  def arrive_at_sector(game)
    puts "You have arrived at sector #{location}!"
    sleep(1)
    claim_territory(game)
    trigger_event(game)
    discover_item(game)
  end

  def claim_territory(game)
    if owner
      puts "This sector is owned by #{owner.name}"
    else
      puts "This sector was unclaimed. You claim it for yourself."
      self.owner = game.current_astronaut
    end
  end 

  Event = Struct.new(:name, :scope, :type, :attribute, :degree)
  def generate_event(game)
    events_array = [
      ["an explosion", [game.current_astronaut], "modifier","morale", -20],
      ["a magnetic field", game.astronauts, "modifier", "fuel", 10],
      ["a curse", [owner], "modifier", "fuel", -5]
    ] 
    num = rand(0..2)
    self.event = Event.new(*events_array[num])
  end

  def trigger_event(game)
    !self.event && generate_event(game)
    puts "This sector contains #{event.name}!"
    recipients = event.scope
    recipients.each {|recipient| recipient.receive_event(event) }
  end

  Item = Struct.new(:name, :scope, :type, :attribute, :degree)
  def generate_item(game)
    items_array = [
      ["a glowing asteroid", [game.current_astronaut], "modifier","speed", 1]
    ] 
    self.item = Item.new(*items_array[0])
  end

  def discover_item(game)
    !self.item && generate_item(game)
    if self.item == -1
      puts "Out the window there is only emptiness"
    else
      puts "Out the window you see a #{item.name}."
      puts "Would you like to retrieve it?"
      choice = gets.chomp
      if choice.match(/(^y$|^yes$)/i)
        game.current_astronaut.retrieve_item(self.item)
        self.item = -1
      end
    end
  end
end

#################

def sector_generator(map_size)
  puts "generating map of size #{map_size}"
  map = {}
  map_size.times do |location|
    location += 1
    map[location] = Sector.new(location)
  end
  return map
end

def astronaut_generator(astronauts)
  astronaut_array = []
  astronauts.times do |x|
    puts "Enter Astronaut #{x+1}'s name: "
    name = gets.chomp
    astronaut_array << Astronaut.new(name)
  end
  return astronaut_array
end

$early_log = CSV.read("captains-logs/initial-log.txt")
$optimist_log = CSV.read("captains-logs/optimist-log.txt")
$pessimist_log = CSV.read("captains-logs/pessimist-log.txt")

moon = CSV.read("moon.txt")
moon.each {|line| puts line[0]}
puts "\n" + "\s"*34 + "TIME TO ORBIT"
puts "\nHow large would you like the map to be? (10 is best)"
print ">>"
map_size = gets.chomp.to_i
map = sector_generator(map_size)
puts "How many astronauts will be orbiting?"
print ">>"
astronauts = gets.chomp.to_i
game = Game.new(astronaut_generator(astronauts), map)
game.start_game

=begin
  Current Issues:
    astronaut.use_item does not eliminate item from collection
    astronaut.use_item unnecessarily involves passing instance of game around as argument so that user_prompt can still call game.lookup_location

=end

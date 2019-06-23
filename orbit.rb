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
    astronauts.each do |astronaut| 
      self.current_astronaut = astronaut
      puts "\n#{current_astronaut.name}'s turn!"
      astronaut.start_turn(self)
    end
    self.day += 1
  end

  def dispatch_effect(event)
    recipients = []
    recipients << send("#{event.scope}")
    recipients.flatten!
    recipients.each {|recipient| recipient.receive_event(event) }
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
end

class Console

  def captains_log(day)
    puts "\n>> CAPTAIN'S LOG >>>> I have been orbiting for #{day} " + (day == 1 ? "day." : "days.")
    print ">> "
    if day < 3
      puts $initial_log[day]
    elsif attributes[:morale] > 75
      entry = rand(0..4)
      puts $optimist_log[entry]
    else
      entry = rand(0..4)
      puts $pessimist_log[entry]
    end
  end

  def list_items(items)
    if items.empty?
      puts "Your collection is empty."
    else
      puts "Your collection holds: "
      items.each_with_index {|item, i| puts "\t" + (i + 1).to_s + ": " + item[:name] + "\n"}
    end
  end

  def show_statistics(attributes, items)
    puts %Q{>> Ship Statistics >>>>
      Current Sector is: #{attributes[:location]}
      Speed is         : #{attributes[:speed]}
      Fuel is          : #{attributes[:fuel]}
      Morale is        : #{attributes[:morale]}
      Collection holds : #{items.size} items
    }
  end

  def list_options
    puts %Q{>> Possible Commands: >>>>
      (d) - Drive ship
      (c) - Collection
      (s) - Ship statistics
      (i) - Use item
    }
  end

  def user_prompt
    puts "How will you proceed? (enter 'ls' to list possible commands)"
    print ">>"
    return gets.chomp.downcase
  end


  def warning(critical_attr)
    puts ">> DANGER >>>> Your #{critical_attr} is low. If it falls any further you may not survive!" 
  end

end

class Astronaut
  attr_accessor :name, :console, :attributes, :items, :turn_over

  EVENTS_ARRAY = CSV.read("events.txt")

  def initialize(name, console)
    @name = name
    @console = console
    @attributes = {
      :location => 1,
      :morale => 100,
      :fuel => 50,
      :speed => 1
    }
    @items = []
    @turn_over = false
  end

  def start_turn(game)
    self.turn_over = false
    console.captains_log(game.day)
    console.warning("morale") if attributes[:morale] < 25
    console.warning("fuel") if attributes[:fuel] < 10
    until turn_over
      user_choice(game)
    end
  end

  def user_choice(game)
    case console.user_prompt
    when "d"
      puts "Driving..."
      sleep(1)
      new_event(game)
      move_ship(game)
      self.turn_over = true
    when "c"
      console.list_items(items)
    when "s"
      console.show_statistics(attributes, items)
    when "i"
      use_item(game)
    when "ls"
      console.list_options
    else
      puts "That command is not executable"
    end
  end

  def receive_event(event)
    var = event.attribute.to_sym
    self.attributes[var] += event.degree.to_i
    puts event.name
    crossed_starting_line?
    puts "#{self.name}'s #{event.attribute} is now #{self.attributes[var]}"
  end

  def retrieve_item(item)
    self.items << item
    console.list_items(items)
  end

  private

    Event = Struct.new(:name, :scope, :attribute, :degree)
    def new_event(game)
      num = rand(0..3)
      event = Event.new(*EVENTS_ARRAY[num])
      game.dispatch_effect(event)
    end

    def calculate_distance
      rand(0..5) + self.attributes[:speed]
    end

    def move_ship(game)
      self.attributes[:location] += calculate_distance
      crossed_starting_line?
      update_fuel
      sector = game.map.lookup_location(attributes[:location])
      sector.arrive_at_sector(self)
    end

    def crossed_starting_line?
      if attributes[:location] < 1
        self.attributes[:location] += 10
      elsif attributes[:location] > 10
        complete_orbit
      end
    end

    def complete_orbit
      self.attributes[:location] -= 10
      self.attributes[:morale] += 10
      puts "You have completed a full orbit! The sensation of progress boosts your morale to #{attributes[:morale]}."
    end

    def update_fuel
      self.attributes[:fuel] -= 2
    end

    def use_item(game)
      puts "Which item will you use?"
      console.list_items(items)
      puts "0: cancel"
      print ">>"
      input = gets.to_i - 1
      if (0..items.size).cover? input
        chosen_item = items[input]
        self.items.delete_at(input)
        recipients = chosen_item.scope
        recipients.each {|recipient| recipient.receive_event(chosen_item) }
      else
        user_choice(game)
      end
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

  def arrive_at_sector(astronaut)
    puts "You have arrived at sector #{location}!"
    sleep(1)
    claim_territory(astronaut)
    # discover_item(game)
  end

  def claim_territory(astronaut)
    if owner
      puts "This sector is owned by #{owner.name}"
    else
      puts "This sector was unclaimed. You claim it for yourself."
      self.owner = astronaut
    end
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


class Map
  attr_accessor :map

  def initialize
    @map = generate_map
  end

  def generate_map
    map = {}
    10.times do |location|
      location += 1
      map[location] = Sector.new(location)
    end
    return map
  end

  def lookup_location(location)
    map[location] || (raise StandardError, "location does not exist in map")
  end
end

def astronaut_generator(astronauts)
  astronaut_array = []
  astronauts.times do |x|
    puts "Enter Astronaut #{x+1}'s name: "
    name = gets.chomp
    astronaut_array << Astronaut.new(name, Console.new)
  end
  return astronaut_array
end

$initial_log = CSV.read("captains-logs/initial-log.txt")
$optimist_log = CSV.read("captains-logs/optimist-log.txt")
$pessimist_log = CSV.read("captains-logs/pessimist-log.txt")



title = CSV.read("title.txt")
title.each {|line| puts line[0]}
puts "\n"*2 + "\s"*36 + "TIME TO ORBIT" + "\n"*2
puts "How many astronauts will be orbiting?"
print ">>"
astronauts = gets.chomp.to_i
game = Game.new(astronaut_generator(astronauts), Map.new)
game.start_game
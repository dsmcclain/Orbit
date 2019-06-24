require 'csv'

class Game
  attr_accessor :astronauts, :map, :turn, :current_astronaut, :day

  def initialize(astronauts, map, turn)
    @astronauts = astronauts
    @map = map
    @turn = turn
    @current_astronaut
    @day = 0
  end

  def start_game
    until astronauts.empty?
      new_turn
    end
    finish_game
  end

  def dispatch_effect(event)
    recipients = []
    recipients << send("#{event.scope}")
    recipients.flatten!
    recipients.each {|recipient| recipient.receive_effect(event) }
  end

  def game_over(astronaut)
    puts "#{astronaut.name} is out of the game"
    self.astronauts.delete(astronaut)
  end

  private

    def new_turn
      astronauts.each do |astronaut| 
        self.current_astronaut = astronaut
        puts "\n#{current_astronaut.name}'s turn!"
        turn.start_turn(astronaut, self)
      end
      self.day += 1
    end

    def finish_game
      puts "Game Over."
    end
end

module Console
  def handwriting_effect(string)
    string.each_char do |char|
       print char
       sleep(0.05)
    end 
  end

  def user_prompt
    puts "How will you proceed? (enter 'ls' to list possible commands)"
    print ">>"
    gets.chomp.downcase
  end

  def list_options
    puts %Q{>> Possible Commands: >>>>
      (d) - Drive ship
      (c) - Collection
      (s) - Ship statistics
      (i) - Use item
    }
  end

  def warning(critical_attr)
    puts ">> DANGER >>>> Your #{critical_attr} is low. If it falls any further you might not survive!" 
  end
end

class Turn
  include Console
  attr_accessor :current_astronaut, :turn_over

  def initialize
    @current_astronaut
    @turn_over = false
  end

  EVENTS_ARRAY = CSV.read("events.txt")
  INITIAL_LOG = CSV.read("captains-logs/initial-log.txt")
  OPTIMIST_LOG = CSV.read("captains-logs/optimist-log.txt")
  PESSIMIST_LOG = CSV.read("captains-logs/pessimist-log.txt")

  def start_turn(astronaut, game)
    self.current_astronaut = astronaut
    captains_log(game.day)
    warning("fuel") if current_astronaut.fuel_level == "critical"
    self.turn_over = false
    until turn_over
      user_choice(game)
    end
    finish_turn(game)
  end

  private
  
    def captains_log(day)
      string = "\n>>>> CAPTAIN'S LOG\n>>I have been orbiting for " +
              "#{day} " + (day == 1 ? "day." : "days.") + "\n>> "
      string.concat(log_message(day))
      handwriting_effect(string)
      puts "\n"*2
      warning("morale") if current_astronaut.morale_level == "critical"
    end

    def log_message(day)
      morale_level = current_astronaut.morale_level
      if day < 4
        msg = INITIAL_LOG[day]
      elsif morale_level == "good"
        entry = rand(0..4)
        msg = OPTIMIST_LOG[entry]
      else
        entry = rand(0..4)
        msg = PESSIMIST_LOG[entry]
      end
      msg[0]
    end

    Event = Struct.new(:message, :scope, :attribute, :degree)
    def new_event
      num = rand(0..3)
      Event.new(*EVENTS_ARRAY[num])
    end

    def user_choice(game)
      case user_prompt
      when "d"
        drive(game)
      when "c"
        current_astronaut.collection.list_items
      when "s"
        current_astronaut.show_statistics
      when "i"
        use_item(game)
      when "ls"
        list_options
      else
        puts "That command is not executable"
      end
    end

    def drive(game)
      puts "Driving..."
      sleep(1)
      game.dispatch_effect(new_event)
      current_astronaut.move_ship(game.map)
      self.turn_over = true
    end

    def use_item(game)
      item = current_astronaut.collection.select_item
      if item
        game.dispatch_effect(item)
      else
        user_choice(game)
      end
    end

    def finish_turn(game)
      game.game_over(current_astronaut) if current_astronaut.game_over
    end
end

class Astronaut
  attr_accessor :name, :collection, :attributes, :game_over

  def initialize(name, collection)
    @name = name
    @collection = collection
    @attributes = {
      :location => 1,
      :morale => 90,
      :fuel => 50,
      :speed => 1
    }
    @game_over = false
  end

  def receive_effect(effect)
    puts effect.message
    attribute = effect.attribute.to_sym
    degree = effect.degree.to_i
    update_attribute(attribute, degree)
    if attribute != :location
      puts "Your #{attribute} is now #{attributes[attribute]}"
    end
  end

  def retrieve_item(item)
    collection.add_item(item)
    collection.list_items
  end

  def move_ship(map)
    update_attribute(:location, calculate_distance)
    update_attribute(:fuel, -2)
    sector = map.lookup_location(attributes[:location])
    sector.arrive_at_sector(self)
  end

  def show_statistics
    puts %Q{>> #{name}'s' Statistics >>>>
      Current Sector is: #{attributes[:location]}
      Speed is         : #{attributes[:speed]}
      Fuel is          : #{attributes[:fuel]}
      Morale is        : #{attributes[:morale]}
      Collection holds : #{collection.items.size} items
    }
  end

  def morale_level
    if attributes[:morale] > 75
      "good"
    elsif attributes[:morale].between?(26,75)
      "bad"
    else
      "critical"
    end
  end

  def fuel_level
    attributes[:fuel] <= 15 ? "critical" : "good"
  end

  private

    def update_attribute(attribute, degree)
      self.attributes[attribute] += degree
      send("check_#{attribute}")
    end

    def calculate_distance
      rand(0..5) + self.attributes[:speed]
    end

    def check_morale
      if attributes[:morale] <= 0
        self.game_over = true
      elsif attributes[:morale] > 100
        self.attributes[:morale] = 100
      end
    end

    def check_fuel
      self.game_over = true if attributes[:fuel] <= 0
    end

    def check_location
      if attributes[:location] < 1
        self.attributes[:location] += 10
      elsif attributes[:location] > 10
        complete_orbit
      end
    end

    def check_speed
      if attributes[:speed] < 0
        self.attributes[:morale] = 0
      end
    end

    def complete_orbit
      self.attributes[:location] -= 10
      puts "You have completed a full orbit! The sensation of progress provides a needed boost!"
      update_attributes(:morale, 10)
    end
end

class Collection
  attr_accessor :items

  def initialize
    @items = []
  end

  def add_item(item)
    self.items << item
  end

  def remove_item(index)
    self.items.delete_at(index)
  end

  def select_item
    list_items
    return nil if items.empty?
    puts "Which item do you choose?"
    print ">>"
    input = gets.to_i - 1
    if (0..items.size).cover? input
      chosen_item = items[input]
      remove_item(input)
      chosen_item
    else
      nil
    end
  end

  def list_items
    if items.empty?
      puts "Your collection is empty."
    else
      puts "Your collection holds: "
      items.each_with_index {|item, i| puts "\t" + (i + 1).to_s + ": " + item[:name] + "\n"}
    end
  end
end

class Sector 
  attr_accessor :location, :owner, :item

  ITEMS_ARRAY = CSV.read("items.txt")

  def initialize(location)
    @location = location
    @owner
    @item
  end

  def arrive_at_sector(astronaut)
    puts "You have arrived at sector #{location}!"
    sleep(1)
    claim_territory(astronaut)
    discover_item(astronaut)
  end

  private

    def claim_territory(astronaut)
      if owner
        puts "This sector is owned by #{owner.name}"
      else
        puts "This sector was unclaimed. You claim it for yourself."
        self.owner = astronaut
      end
    end 

    Item = Struct.new(:name, :message, :scope, :attribute, :degree)
    def generate_item
      self.item = Item.new(*ITEMS_ARRAY[0])
    end

    def discover_item(astronaut)
      !self.item && generate_item
      if self.item == -1
        no_item
      else
        show_item(astronaut)
      end
    end

    def no_item
      puts "Out the window there is only emptiness"
    end

    def show_item(astronaut)
      puts "Out the window you see a #{item.name}."
      puts "Would you like to retrieve it?"
      choice = gets.chomp
      if choice.match(/(^y$|^yes$)/i)
        astronaut.retrieve_item(item)
        self.item = -1
      end
    end
end

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

######GAME INITIALIZATION METHODS#########

def print_introduction
  puts "You have secured orbit around an unknown planet."
  sleep(2)
  puts "Your goal is to discover as much as you can while staying alive."
  sleep(2)
  puts "There are no guarantees."
  sleep(2)
end

def welcome_screen
  title = CSV.read("title.txt")
  title.each {|line| puts line[0]}
  puts "\n"*4
  puts "How many astronauts will be orbiting?"
  print ">>"
end

def astronaut_generator(astronauts)
  astronaut_array = []
  astronauts.times do |x|
    puts "Enter Astronaut #{x+1}'s name: "
    name = gets.chomp
    astronaut_array << Astronaut.new(name, Collection.new)
  end
  return astronaut_array
end

welcome_screen
astronauts = gets.chomp.to_i
game = Game.new(astronaut_generator(astronauts), Map.new, Turn.new)
print_introduction
game.start_game
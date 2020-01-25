require 'csv'

class Game
  attr_accessor :astronauts, :turn

  def initialize(astronauts, turn)
    @astronauts = astronauts
    @turn = turn
  end

  def start_game
    until astronauts.empty?
      turn.play(self)
    end
    finish_game
  end

  def remove_astronaut(astronaut)
    puts "#{astronaut.name} is out of the game"
    self.astronauts.delete(astronaut)
  end

  def dispatch_effect(event, current_astronaut)
    recipients = case event.scope
    when "current astronaut"
      [current_astronaut]
    when "all"
      astronauts
    end
    puts event.message
    recipients.each {|recipient| recipient.receive_effect(event) }
  end

  private
    def finish_game
      puts "Game Over."
    end
end

class Log 
  INITIAL_LOG = CSV.read("captains-logs/initial-log.txt")
  OPTIMIST_LOG = CSV.read("captains-logs/optimist-log.txt")
  PESSIMIST_LOG = CSV.read("captains-logs/pessimist-log.txt")

  def daily_log(day, morale)
    string = "\n>>>> CAPTAIN'S LOG\n>>I have been orbiting for " +
            "#{day} " + (day == 1 ? "day." : "days.") + "\n>> "
    string.concat(log_message(day, morale))
    puts_as_handwriting(string)
    puts "\n"*2
  end

  def user_prompt
    puts "How will you proceed? (enter 'p' to list possible commands)"
    print ">>"
    gets.chomp.downcase
  end

  def list_options
    puts %Q{>> Possible Commands: >>>>
      (d) - Drive ship
      (f) - Drift ship
      (i) - Use item
      (c) - Collection
      (s) - Ship statistics
    }
  end

  def warning(critical_attr)
    puts ">> DANGER >>>> Your #{critical_attr} is low. If it falls any further you might not survive!" 
  end

  private
    def puts_as_handwriting(string)
      string.each_char do |char|
        print char
        sleep(0.05)
      end 
    end
    
    def log_message(day, morale)
      if day < 4
        INITIAL_LOG[day][0]
      elsif morale == "good"
        choose_message(OPTIMIST_LOG)
      else
        choose_message(PESSIMIST_LOG)
      end
    end

    def choose_message(log)
      limit = log.size - 1
      entry = rand(0..limit)
      log[entry][0]
    end
end

class Turn
  attr_accessor :map, :current_astronaut, :turn_over, :day, :log

  def initialize(map)
    @map = map
    @current_astronaut
    @turn_over = false
    @day = 0
    @log = Log.new
  end

  EVENTS_ARRAY = CSV.read("events.txt")

  def play(game)
    game.astronauts.each do |astronaut|
      puts "\n#{astronaut.name}'s turn!"
      start_turn(astronaut, game)
      game.remove_astronaut(current_astronaut) if current_astronaut.game_over
    end
    self.day += 1
  end

  def start_turn(astronaut, game)
    self.current_astronaut = astronaut
    log.daily_log(day, current_astronaut.morale_level)
    look_for_warnings
    self.turn_over = false
    until turn_over
      get_input(game)
    end
  end

  private
    Event = Struct.new(:message, :scope, :attribute, :degree)
    def new_event
      num = rand(0..11)
      Event.new(*EVENTS_ARRAY[num])
    end

    def look_for_warnings
      log.warning("morale") if current_astronaut.morale_level == "critical"
      log.warning("fuel") if current_astronaut.fuel_level == "critical"
    end

    def get_input(game)
      case log.user_prompt
      when "d"
        puts "Driving..."
        drive(map, game)
      when "f"
        puts "Drifting..."
        drift(map, game)
      when "c"
        current_astronaut.collection.list_items
      when "s"
        current_astronaut.show_statistics
      when "i"
        use_item(game)
      when "p"
        log.list_options
      else
        puts "That command is not executable"
      end
    end

    def drive(map, game)
      sleep(1)
      game.dispatch_effect(new_event, current_astronaut)
      current_astronaut.drive_ship(map)
      self.turn_over = true
    end

    def drift(map, game)
      sleep(1)
      game.dispatch_effect(new_event, current_astronaut)
      current_astronaut.drift_ship(map)
      self.turn_over = true
    end

    def use_item(game)
      item = item_chosen
      if item
        game.dispatch_effect(item, current_astronaut)
        self.turn_over = true
      else 
        get_input(game)
      end
    end

    def item_chosen
      current_astronaut.collection.select_item
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
      :speed => 1,
      :sectors => [1]
    }
    @game_over = false
  end

  def receive_effect(effect)
    attribute = effect.attribute.to_sym
    degree = effect.degree.to_i
    update_attribute(attribute, degree)
  end

  def retrieve_item(item)
    collection.add_item(item)
    collection.list_items
  end

  def drive_ship(map)
    move_ship(map, -4, calculate_distance)
  end

  def drift_ship(map)
    move_ship(map, -1, 1)
  end

   ##DOES NOT BELONG
  def show_statistics
    puts %Q{>> #{name}'s' Statistics >>>>
      Current Sector is: #{attributes[:location]}
      Speed is         : #{attributes[:speed]}
      Fuel is          : #{attributes[:fuel]}
      Morale is        : #{attributes[:morale]}
      Collection holds : #{collection.items.size} items
      Sectors explored : #{pp attributes[:sectors]}
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

    def move_ship(map, fuel_cost, distance)
      update_attribute(:fuel, fuel_cost)
      update_attribute(:location, distance)
      mark_as_explored(attributes[:location])
      victory_condition?
      sector = map.lookup_location(attributes[:location])
      sector.arrive_at_sector(self)
    end

    def update_attribute(attribute, degree)
      self.attributes[attribute] += degree
      send("check_#{attribute}")
    end

    def mark_as_explored(location)
      if attributes[:sectors].include?(location)
        puts "You have already explored this sector."
      else
        self.attributes[:sectors] << location
        self.attributes[:sectors].sort!
        puts "This sector is new to you."
      end
    end

    def victory_condition?
      puts "You have explored every sector!" if attributes[:sectors].size == 20
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
        self.attributes[:location] += 20
      elsif attributes[:location] > 20
        complete_orbit
      end
    end

    def check_speed
      if attributes[:speed] < 0
        self.attributes[:morale] = 0
      end
    end

    def complete_orbit
      self.attributes[:location] -= 20
      puts "You have completed a full orbit! The sensation of progress provides a needed boost!"
      update_attribute(:morale, 15)
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
  attr_accessor :location, :item

  ITEMS_ARRAY = CSV.read("items.txt")

  def initialize(location)
    @location = location
    @item
  end

  def arrive_at_sector(astronaut)
    puts "You have arrived at sector #{location}!"
    sleep(1)
    discover_item(astronaut)
  end

  private

    Item = Struct.new(:name, :message, :scope, :attribute, :degree)
    def generate_item
      selection = rand(0..10)
      self.item = Item.new(*ITEMS_ARRAY[selection])
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
      puts "Out the window you see #{item.name}."
      puts "Would you like to retrieve it?"
      choice = gets.chomp
      until yesno?(choice)
        puts "Please enter yes or no"
        choice = gets.chomp
      end
      if choice.match(/(^y$|^yes$)/i)
        astronaut.retrieve_item(item)
        self.item = -1
      end
    end

    def yesno?(input)
      input.match(/(^y$|^yes$)/i) || input.match(/(^n$|^no$)/i)
    end
end

class Map
  attr_accessor :map

  def initialize
    @map = generate_map
  end

  def generate_map
    map = {}
    20.times do |location|
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
number_of_players = gets.chomp.to_i
game = Game.new(astronaut_generator(number_of_players), Turn.new(Map.new))
print_introduction
game.start_game
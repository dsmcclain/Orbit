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
    astronauts.each {|astronaut| astronaut.initiate_game(self)}
    until astronauts.empty?
      new_turn
    end
    finish_game
  end

  def new_turn
    astronauts.each do |astronaut| 
      self.current_astronaut = astronaut
      puts "\n#{current_astronaut.name}'s turn!"
      astronaut.start_turn
    end
    self.day += 1
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

module Console
  INITIAL_LOG = CSV.read("captains-logs/initial-log.txt")
  OPTIMIST_LOG = CSV.read("captains-logs/optimist-log.txt")
  PESSIMIST_LOG = CSV.read("captains-logs/pessimist-log.txt")

  def captains_log(day, morale)
    string = "\n>>>> CAPTAIN'S LOG\n>>I have been orbiting for " +
             "#{day} " + (day == 1 ? "day." : "days.") + "\n>> "
    if day < 4
      msg = INITIAL_LOG[day]
    elsif morale > 75
      entry = rand(0..4)
      msg = OPTIMIST_LOG[entry]
    else
      entry = rand(0..4)
      msg = PESSIMIST_LOG[entry]
    end
    string.concat(msg[0])
    handwriting_effect(string)
    puts "\n"*2
  end

  def handwriting_effect(string)
    string.each_char do |char|
       print char
       sleep(0.05)
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
    gets.chomp.downcase
  end


  def warning(critical_attr)
    puts ">> DANGER >>>> Your #{critical_attr} is low. If it falls any further you may not survive!" 
  end
end

class Astronaut
  include Console
  attr_accessor :name, :attributes, :items, :turn_over, :game_over, :game

  EVENTS_ARRAY = CSV.read("events.txt")

  def initialize(name)
    @name = name
    @attributes = {
      :location => 1,
      :morale => 90,
      :fuel => 50,
      :speed => 1
    }
    @items = []
    @turn_over = false
    @game_over = false
    @game
  end

  def initiate_game(game)
    self.game = game
  end

  def start_turn
    self.turn_over = false
    captains_log(game.day, attributes[:morale])
    warning("morale") if attributes[:morale] < 25
    warning("fuel") if attributes[:fuel] < 10
    until turn_over
      user_choice
    end
    finish_turn
  end

  def receive_effect(effect)
    puts effect.message
    attribute = effect.attribute.to_sym
    degree = effect.degree.to_i
    update_attribute(attribute, degree)
  end

  def retrieve_item(item)
    self.items << item
    list_items(items)
  end

  private
    def user_choice
      case user_prompt
      when "d"
        drive
      when "c"
        list_items(items)
      when "s"
        show_statistics(attributes, items)
      when "i"
        use_item
      when "ls"
        list_options
      else
        puts "That command is not executable"
      end
    end
    
    def drive
      puts "Driving..."
      sleep(1)
      game.dispatch_effect(new_event)
      move_ship(game.map)
      self.turn_over = true
    end

    def use_item
      chosen_item = choose_item
      if chosen_item
        game.dispatch_effect(chosen_item)
      else
        user_choice
      end
    end

    Event = Struct.new(:message, :scope, :attribute, :degree)
    def new_event
      num = rand(0..3)
      Event.new(*EVENTS_ARRAY[num])
    end

    def move_ship(map)
      update_attribute(:location, calculate_distance)
      update_attribute(:fuel, -2)
      sector = map.lookup_location(attributes[:location])
      sector.arrive_at_sector(self)
    end

    def update_attribute(attribute, degree)
      self.attributes[attribute] += degree
      send("check_#{attribute}")
      puts "#{self.name}'s #{attribute} is now #{attributes[attribute]}"
    end

    def calculate_distance
      rand(0..5) + self.attributes[:speed]
    end

    def choose_item
      puts "Which item will you use?"
      list_items(items)
      puts "\t" + "0: cancel"
      print ">>"
      input = gets.to_i - 1
      if (0..items.size).cover? input
        chosen_item = items[input]
        self.items.delete_at(input)
        chosen_item
      else
        nil
      end
    end

    def check_morale
      if attributes[:morale] < 100
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
      update_attributes(:morale, 10)
      puts "You have completed a full orbit! The sensation of progress boosts your morale to #{attributes[:morale]}."
    end

    def finish_turn
      game.game_over(self) if game_over
    end
end

class Sector 
  attr_accessor :location, :owner, :event, :item

  ITEMS_ARRAY = CSV.read("items.txt")

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
        puts "Out the window there is only emptiness"
      else
        puts "Out the window you see a #{item.name}."
        puts "Would you like to retrieve it?"
        choice = gets.chomp
        if choice.match(/(^y$|^yes$)/i)
          astronaut.retrieve_item(item)
          self.item = -1
        end
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
    astronaut_array << Astronaut.new(name)
  end
  return astronaut_array
end

welcome_screen
astronauts = gets.chomp.to_i
game = Game.new(astronaut_generator(astronauts), Map.new)
game.start_game
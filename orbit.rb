class Game
  attr_accessor :astronauts, :map, :current_astronaut, :day

  def initialize(astronauts, map)
    @astronauts = astronauts
    @map = map
    @current_astronaut
    @day = 0
  end

  def start_game
    while day < 10
      new_turn
    end
    finish_game
  end

  def new_turn
    astronauts.each {|astronaut| 
      self.current_astronaut = astronaut
      astronaut.start_turn(self)}
    self.day += 1
    puts "You have been orbiting for #{day} " + (day > 1 ? "days." : "day.")
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
end

class Astronaut
  attr_accessor :name, :attributes, :items

  def initialize(name)
    @name = name
    @attributes = {
      :location => 0,
      :funds => 1000,
      :fuel => 50,
      :speed => 1
    }
    @items = []
  end

  def start_turn(game)
    puts "#{name}'s turn!'"
    move_ship
    update_fuel
    game.lookup_location
  end

  def receive_event(event)
    var = event.attribute.to_sym
    self.attributes[var] += event.degree
    check_location
    puts "#{self.name}'s #{event.attribute} is now #{self.attributes[var]}"
  end

  def retrieve_item(item)
    self.items << item
    puts "You now hold: "
    self.items.each {|item| puts item[:name] + "\n"}
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
      collect_contracts
    end

    def collect_contracts
      self.attributes[:funds] += 100
      puts "The consortium rewards your progress! Your funds are now #{attributes[:funds]}."
    end

    def update_fuel
      self.attributes[:fuel] -= 2
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
      ["an explosion", [game.current_astronaut], "modifier","funds", -200],
      ["a magnetic field", game.astronauts, "modifier", "funds", 10],
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

puts "Time to go to Orbit"
puts "How large would you like the map to be? 10 is best)"
map_size = gets.chomp.to_i
map = sector_generator(map_size)
puts "How many astronauts will be orbiting?"
astronauts = gets.chomp.to_i
game = Game.new(astronaut_generator(astronauts), map)
game.start_game
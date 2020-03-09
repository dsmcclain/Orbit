class Turn
  require 'csv'

  attr_accessor :map, :astronaut, :turn_over, :day, :game

  UPLIFTING_EVENTS = CSV.read("uplifting_events.txt", col_sep: '|')
  DEPRESSING_EVENTS = CSV.read("depressing_events.txt", col_sep: '|')

  def initialize(map)
    @map = map
    @astronaut
    @turn_over = false
    @day = 0
  end

  def play(game)
    @game = game
    game.astronauts.each do |astronaut|
      puts "\n#{astronaut.name}'s turn!"
      start_turn(astronaut)
      game.remove_astronaut(astronaut) if astronaut.game_over
    end
    self.day += 1
  end

  def start_turn(astronaut)
    self.astronaut = astronaut
    astronaut.show_statistics
    astronaut.daily_log(day)
    look_for_warnings
    self.turn_over = false
    until turn_over
      get_input
    end
  end

  private

    Event = Struct.new(:message, :scope, :attribute, :degree)

    def new_event
      events_array = astronaut.attributes[:location] < 10 ? DEPRESSING_EVENTS : UPLIFTING_EVENTS
      num = rand(0..8)
      Event.new(*events_array[num])
    end

    def look_for_warnings
      astronaut.warning("morale") if astronaut.attributes[:morale] < 5
      astronaut.warning("fuel") if astronaut.fuel_level == "critical"
    end

    def get_input
      case astronaut.user_prompt
      when "d"
        puts "Driving..."
        drive(map)
      when "f"
        puts "Drifting..."
        drift(map)
      when "c"
        astronaut.collection.list_items
      when "s"
        astronaut.show_statistics
      when "i"
        use_item
      when "p"
        astronaut.list_options
      else
        puts "That command is not executable"
      end
    end

    def drive(map)
      sleep(1)
      game.dispatch_effect(new_event, astronaut)
      astronaut.drive_ship(map)
      self.turn_over = true
    end

    def drift(map)
      sleep(1)
      game.dispatch_effect(new_event, astronaut)
      astronaut.drift_ship(map)
      self.turn_over = true
    end

    def use_item
      item = item_chosen
      if item
        game.dispatch_effect(item, astronaut)
        self.turn_over = true
      else 
        get_input
      end
    end

    def item_chosen
      astronaut.collection.select_item
    end
end

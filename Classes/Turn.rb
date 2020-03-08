class Turn
  attr_accessor :map, :astronaut, :turn_over, :day, :log

  UPLIFTING_EVENTS = CSV.read("uplifting_events.txt", col_sep: '|')
  DEPRESSING_EVENTS = CSV.read("depressing_events.txt", col_sep: '|')

  def initialize(map)
    @map = map
    @astronaut
    @turn_over = false
    @day = 0
    @log = Log.new
  end

  def play(game)
    game.astronauts.each do |astronaut|
      puts "\n#{astronaut.name}'s turn!"
      start_turn(astronaut, game)
      game.remove_astronaut(astronaut) if astronaut.game_over
    end
    self.day += 1
  end

  def start_turn(astronaut, game)
    self.astronaut = astronaut
    astronaut.show_statistics(log.morale_options)
    log.daily_log(day, astronaut.attributes[:morale])
    look_for_warnings
    self.turn_over = false
    until turn_over
      get_input(game)
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
      log.warning("morale") if astronaut.attributes[:morale] < 5
      log.warning("fuel") if astronaut.fuel_level == "critical"
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
        astronaut.collection.list_items
      when "s"
        astronaut.show_statistics(log.morale_options)
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
      game.dispatch_effect(new_event, astronaut)
      astronaut.drive_ship(map)
      self.turn_over = true
    end

    def drift(map, game)
      sleep(1)
      game.dispatch_effect(new_event, astronaut)
      astronaut.drift_ship(map)
      self.turn_over = true
    end

    def use_item(game)
      item = item_chosen
      if item
        game.dispatch_effect(item, astronaut)
        self.turn_over = true
      else 
        get_input(game)
      end
    end

    def item_chosen
      astronaut.collection.select_item
    end
end

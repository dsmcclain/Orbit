class Turn
  attr_accessor :map, :current_astronaut, :turn_over, :day, :log

  def initialize(map)
    @map = map
    @current_astronaut
    @turn_over = false
    @day = 0
    @log = Log.new
  end

  EVENTS_ARRAY = CSV.read("depressing_events.txt", col_sep: '|')

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
    log.daily_log(day, current_astronaut.attributes[:morale])
    look_for_warnings
    self.turn_over = false
    until turn_over
      get_input(game)
    end
  end

  private

    Event = Struct.new(:message, :scope, :attribute, :degree)

    def new_event
      num = rand(0..8)
      Event.new(*EVENTS_ARRAY[num])
    end

    def look_for_warnings
      log.warning("morale") if current_astronaut.attributes[:morale] < 5
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
        current_astronaut.show_statistics(log.morale_options)
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

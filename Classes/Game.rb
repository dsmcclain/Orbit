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

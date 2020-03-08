class Astronaut
  include Console
  attr_accessor :name, :collection, :attributes, :game_over

  def initialize(name, collection)
    @name = name
    @collection = collection
    @attributes = {
      :location => 1,
      :morale => 16,
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

  def translate_morale(morale_options)
    morale_options[attributes[:morale]]
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
      if attributes[:morale] < 0 || attributes[:morale] > 32
        self.game_over = true
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
      update_attribute(:morale, 5)
    end
end

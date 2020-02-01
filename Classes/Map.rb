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

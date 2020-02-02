require './Modules/ItemFactory.rb'

class Map
  include ItemFactory

  attr_accessor :map

  def initialize
    @items = generate_items
    @map = generate_map
  end

  def generate_map
    map = {}
    20.times do |location|
      item = @items[location]
      location += 1
      map[location] = Sector.new(location, item)
    end
    map
  end

  def lookup_location(location)
    map[location] || (raise StandardError, "location does not exist in map")
  end
end

module ItemFactory
  Item = Struct.new(:name, :message, :scope, :attribute, :degree)

  ROCK_DATA = CSV.read("rocks.txt", col_sep: '|')
  VAPOR_DATA = CSV.read("vapors.txt", col_sep: '|')
  SPORE_DATA = CSV.read("spores.txt", col_sep: '|')

  def generate_items
    items = []
    20.times do |i|
      num = rand(1..6)
      if num <= 3
        items << generate_space_rock
      elsif num <= 5
        items << generate_tinted_vapor
      else
        items << generate_spores
      end
    end
    items
  end

  def generate_space_rock
    data = ROCK_DATA[rand(0..4)]
    msg = 'Careful research of this rock reveals that ' + data[0]
    Item.new('space rock', msg, data[1], data[2], data[3])
  end

  def generate_tinted_vapor
    data = VAPOR_DATA[rand(0..4)]
    msg = 'While you are studying the vapor ' + data[1]
    Item.new("#{data[0]}-tinted vapor", msg, data[2], data[3], data[4])
  end

  def generate_spores
    data = SPORE_DATA[rand(0..2)]
    Item.new('a cluster of spores', data[0], data[1], data[2], data[3])
  end
end
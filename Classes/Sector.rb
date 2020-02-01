class Sector 
  attr_accessor :location, :item

  ITEMS_ARRAY = CSV.read("items.txt", col_sep: '|')

  def initialize(location)
    @location = location
    @item
  end

  def arrive_at_sector(astronaut)
    puts "You have arrived at sector #{location}!"
    sleep(1)
    discover_item(astronaut)
  end

  private

    Item = Struct.new(:name, :message, :scope, :attribute, :degree)

    def generate_item
      selection = rand(0..10)
      self.item = Item.new(*ITEMS_ARRAY[selection])
    end

    def discover_item(astronaut)
      generate_item unless self.item
      self.item == "empty" ? no_item : show_item(astronaut)
    end

    def no_item
      puts "Out the window there is only emptiness"
    end

    def show_item(astronaut)
      puts "Out the window you see #{item.name}."
      puts "Would you like to retrieve it?"
      choice = gets.chomp
      until yesno?(choice)
        puts "Please enter yes or no"
        choice = gets.chomp
      end
      if choice.match(/(^y$|^yes$)/i)
        astronaut.retrieve_item(item)
        self.item = "empty"
      end
    end

    def yesno?(input)
      input.match(/(^y$|^yes$)/i) || input.match(/(^n$|^no$)/i)
    end
end

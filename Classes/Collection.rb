class Collection
  attr_accessor :items

  def initialize
    @items = []
  end

  def list_items
    if items.empty?
      puts "Your collection is empty."
    else
      puts "Your collection holds: "
      items.each_with_index {|item, i| puts "\t" + (i + 1).to_s + ": " + item[:name] + "\n"}
    end
  end

  def select_item
    list_items
    puts "Which item do you choose?"
    print ">>"
    input = gets.to_i - 1
    if (0..items.size).cover? input
      chosen_item = items[input]
      remove_item(input)
      chosen_item
    else
      puts "That item doesn't exist."
    end
  end

  def add_item(item)
    self.items << item
  end

  def remove_item(index)
    self.items.delete_at(index)
  end
end

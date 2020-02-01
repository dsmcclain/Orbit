class Collection
  attr_accessor :items

  def initialize
    @items = []
  end

  def select_items
    if items.empty
      puts "Your collection is empty."
    else
      list_items_and_choose
    end
  end

  def list_items_and_choose
    puts "Your collection holds: "
    items.each_with_index {|item, i| puts "\t" + (i + 1).to_s + ": " + item[:name] + "\n"}
    if (0..items.size).cover? input
      chosen_item = items[input]
      remove_item(input)
      chosen_item
    else
      nil
    end
  end

  def add_item(item)
    self.items << item
  end

  def remove_item(index)
    self.items.delete_at(index)
  end
end

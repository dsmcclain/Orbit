module Console
  def buffer
    31 + name.length
  end

  def buffer_line
    '>' * buffer
  end

  def show_statistics(morale_options)
    puts %Q{>>>>>>>> #{name.upcase}'S STATISTICS >>>>>>>>
#{buffer_line}
      Current Sector is: #{attributes[:location]}
      Speed is         : #{attributes[:speed]}
      Fuel is          : #{attributes[:fuel]}
      Morale is        : #{translate_morale(morale_options)}
      Collection holds : #{collection.items.size} items
      Sectors explored : #{attributes[:sectors]}
#{buffer_line}
#{buffer_line}}
  end
end
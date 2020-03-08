module Console
  require 'csv'

  INITIAL_LOG = CSV.read("captains-logs/initial-log.txt")
  OPTIMIST_LOG = CSV.read("captains-logs/optimist-log.txt")
  PESSIMIST_LOG = CSV.read("captains-logs/pessimist-log.txt")
  MORALE_OPTIONS = File.readlines("morale.txt", chomp:true)

  def daily_log(day)
    string = "\n>>>> CAPTAIN'S LOG\n>>I have been orbiting for " +
            "#{day} " + (day == 1 ? "day." : "days.") + "\n>> "
    string.concat(log_message(day))
    puts_as_handwriting(string)
    puts "\n"*2
  end

  def user_prompt
    puts "How will you proceed? (enter 'p' to list possible commands)"
    print ">>"
    gets.chomp.downcase
  end

  def list_options
    puts %Q{>> Possible Commands: >>>>
      (d) - Drive ship
      (f) - Drift ship
      (i) - Use item
      (c) - Collection
      (s) - Ship statistics
    }
  end

  def warning(critical_attr)
    puts ">> DANGER >>>> Your #{critical_attr} is low. If it falls any further you might not survive!" 
  end

  def show_statistics
    puts %Q{>>>>>>>> #{name.upcase}'S STATISTICS >>>>>>>>
#{buffer_line}
      Current Sector is: #{attributes[:location]}
      Speed is         : #{attributes[:speed]}
      Fuel is          : #{attributes[:fuel]}
      Morale is        : #{translate_morale}
      Collection holds : #{collection.items.size} items
      Sectors explored : #{attributes[:sectors]}
#{buffer_line}
#{buffer_line}}
  end

private

  def puts_as_handwriting(string)
    string.each_char do |char|
      print char
      sleep(0.05)
    end
  end

  def log_message(day)
    return INITIAL_LOG[day][0] if day < 4
    attributes[:morale] > 17 ? choose_message(OPTIMIST_LOG) : choose_message(PESSIMIST_LOG)
  end

  def choose_message(log)
    limit = log.size - 1
    entry = rand(0..limit)
    log[entry][0]
  end

  def translate_morale
    MORALE_OPTIONS[attributes[:morale]]
  end

  def buffer
    31 + name.length
  end

  def buffer_line
    '>' * buffer
  end
end
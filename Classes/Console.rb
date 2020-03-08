module Console
  def buffer
    31 + name.length
  end

  def buffer_line
    '>' * buffer
  end
end
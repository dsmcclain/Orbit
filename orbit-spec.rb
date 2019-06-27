#This test file depends on RSpec version 3.8
require_relative 'orbit.rb'

RSpec.describe Game do
  it "initializes astronauts correctly" do
    game = Game.new(astronaut_generator(3), Turn.new(Map.new))
    expect(game.astronauts.size).to eq 3
  end
end
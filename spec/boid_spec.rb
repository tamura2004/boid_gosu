require_relative "../lib/boid"

describe Boid do

  subject(:boid){
    Boid.new(100,50,135,5)
  }

  it{ expect(boid.pos).to eq 100+50i }
end
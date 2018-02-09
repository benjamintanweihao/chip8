defmodule Chip8.Display do
  @doc "Intialize new display"
  def new do
    for x <- 0..63,
        y <- 0..31,
        do: {{x, y}, 0},
        into: %{}
  end
end

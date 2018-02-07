defmodule Chip8.Display do

  @doc "Intialize new display"
  def new do
    for x <- 0..63, into: %{} do
      ys = for y <- 0..31, into: %{}, do: {y, ""}
      {x, ys}
    end
  end

end

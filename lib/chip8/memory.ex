defmodule Chip8.Memory do
  @doc "Initialize the CHIP-8 memory"
  def new do
    for x <- 0..4095, into: %{}, do: {x, <<>>}
  end
end

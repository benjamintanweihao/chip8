defmodule Chip8.Memory do

  @doc "Initialize the CHIP-8 memory"
  def new do
    for x <- 0..4095, into: %{} do
      key =
        x
        |> Integer.to_string(16)
        |> String.pad_leading(3, "0")

      {key, <<>>}
    end
  end
end

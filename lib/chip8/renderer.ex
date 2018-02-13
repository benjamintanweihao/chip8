defmodule Chip8.Renderer do
  @callback render(Chip8.Display, Chip8.Display) :: :ok | {:error, String.t()}
end

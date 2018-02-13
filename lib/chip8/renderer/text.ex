defmodule Chip8.Renderer.Text do
  @behaviour Chip8.Renderer

  use GenServer

  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: __MODULE__)
  end

  def init(game) do
    {:ok, game}
  end

  def render(_prev_display, new_display) do
    concatentated =
      for y <- 0..31,
          x <- 0..63 do
        case Map.fetch!(new_display, {x, y}) do
          1 ->
            "⬛"

          0 ->
            "⬜"
        end
      end

    # Group into 64
    concatentated
    |> Enum.chunk_every(64)
    |> Enum.map(fn chunk ->
      Enum.join(chunk)
    end)
    |> Enum.join("\n")
    |> IO.puts()
  end
end

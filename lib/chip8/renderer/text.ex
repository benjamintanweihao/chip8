defmodule Chip8.Renderer.Text do
  @behaviour Chip8.Renderer

  def render(display) do
    concatentated =
      for y <- 0..31,
          x <- 0..63 do
        case Map.fetch!(display, {x, y}) do
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
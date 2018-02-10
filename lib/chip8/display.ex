defmodule Chip8.Display do
  # TODO: Access protocol?

  @doc "Intialize new display"
  def new do
    for x <- 0..63,
        y <- 0..31,
        do: {{x, y}, 0},
        into: %{}
  end

  # TODO: Convert this to a protocol
  def to_string(display) do
    concatentated =
    for y <- 0..31, x <- 0..63 do
      case Map.fetch!(display, {x, y}) do
        1 ->
          "@"
        0 ->
          "."
      end
    end

    # Group into 64
    concatentated
    |> Enum.chunk_every(64)
    |> Enum.map(fn chunk ->
      Enum.join(chunk)
    end)
    |> Enum.join("\n")
  end
end



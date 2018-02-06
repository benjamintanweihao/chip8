defmodule Chip8.ROM do
  use Bitwise

  def load(file_path) do
    {:ok, rom} = File.read(file_path)
    read(rom, [])
  end

  defp read(<<intr_1::size(8), intr_2::size(8), rest::binary>>, instructions) do
    opcode =
      (intr_1 <<< 8 ||| intr_2)
      |> Integer.to_string(16)
      |> String.pad_leading(4, "0")

    read(rest, [opcode | instructions])
  end

  defp read(<<>>, instructions) do
    Enum.reverse(instructions)
  end
end

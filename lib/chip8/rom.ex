defmodule Chip8.ROM do
  use Bitwise

  def load_into_memory(file_path, memory) do
    instructions = load(file_path)
    do_load_into_memory(memory, 0x200, instructions)
  end

  def load(file_path) do
    {:ok, rom} = File.read(file_path)
    read(rom, [])
  end

  defp do_load_into_memory(memory, address, [first | rest]) do
    updated_memory = Map.replace!(memory, address, first)
    do_load_into_memory(updated_memory, address + 1, rest)
  end

  defp do_load_into_memory(memory, _address, []) do
    memory
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

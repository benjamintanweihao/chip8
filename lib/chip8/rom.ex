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

  defp read(<<instr::size(8), rest::binary>>, instructions) do
    read(rest, [instr | instructions])
  end

  defp read(<<>>, instructions) do
    Enum.reverse(instructions)
  end
end

defmodule Chip8Test do
  use ExUnit.Case
  doctest Chip8

  test "reading the ROM" do
    file_path = Path.expand("../roms/pong.rom", __DIR__)

    instructions = Chip8.ROM.load(file_path)

    assert hd(instructions) == "6A02"
    assert List.last(instructions) == "0000"
  end
end

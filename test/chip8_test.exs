defmodule Chip8Test do
  use ExUnit.Case
  doctest Chip8

  test "reading the ROM" do
    file_path = Path.expand("../roms/pong.rom", __DIR__)

    instructions = Chip8.ROM.load(file_path)

    assert hd(instructions) == "6A02"
    assert List.last(instructions) == "0000"
  end

  test "initialize display" do
    display = Chip8.Display.new()

    assert length(Map.keys(display)) == 64
  end

  test "initialize CHIP-8" do
    {:ok, pid} = Chip8.start_link()

    Process.sleep(100)
  end
end

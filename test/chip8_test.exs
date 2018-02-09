defmodule Chip8Test do
  use ExUnit.Case
  doctest Chip8

  alias Chip8.Display
  alias Chip8.Memory
  alias Chip8.ROM
  alias Chip8.State

  test "reading the ROM" do
    file_path = Path.expand("../roms/pong.rom", __DIR__)

    instructions = ROM.load(file_path)

    assert hd(instructions) == "6A02"
    assert List.last(instructions) == "0000"
  end

  test "initialize display" do
    display = Chip8.Display.new()

    assert length(Map.keys(display)) == 64 * 32
  end

  test "initialize CHIP-8" do
    {:ok, pid} = Chip8.start_link()

    assert Process.alive?(pid)
  end

  describe "opcodes" do
    test "8xy4" do
      assert %{v1: 0xFE, v2: 0xFF, vF: 1} = Chip8.execute("8124", %State{v1: 0xFF, v2: 0xFF})
    end

    test "Dxyn" do
      state = %Chip8.State{v1: 0x0, v2: 0x0, i: 0, display: Display.new(), memory: Memory.new()}
      new_state = Chip8.execute("D005", state)
    end
  end
end

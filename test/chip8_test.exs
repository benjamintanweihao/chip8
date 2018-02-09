defmodule Chip8Test do
  use ExUnit.Case
  doctest Chip8

  alias Chip8.Display
  alias Chip8.Memory
  alias Chip8.ROM
  alias Chip8.State

  import Chip8

  use Bitwise

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

  test "00E0: Clear the display" do
    state = %State{v1: 0x0, v2: 0x0, i: 0, display: Display.new(), memory: Memory.new()}

    %State{display: display} = state |> execute("D005") |> execute("00E0")

    assert display == Display.new()
  end

  test "00EE: Return from a subroutine" do
    state = %State{sp: 2, stack: [0xFF]}

    assert %State{sp: 1, stack: [], pc: 0xFF} == state |> execute("00EE")
  end

  test "1nnn: Jump to location at nnn" do
    assert %State{pc: 0xACE} == execute(%State{}, "1ACE")
  end

  test "2nnn: Call subroutine at nnn" do
    state = %State{sp: 1, stack: [0xAAA], pc: 0xBBB}

    assert %State{sp: 2, stack: [0xBBB, 0xAAA], pc: 0xACE} == execute(state, "2ACE")
  end

  test "3xkk: Skip next instruction if Vx = kk" do
    state = %State{vC: 0xAB, pc: 2}

    assert %State{vC: 0xAB, pc: 4} == execute(state, "3CAB")
  end

  test "4xkk: Skip next instruction if Vx != kk" do
    state = %State{vC: 0xAB, pc: 2}

    assert %State{vC: 0xAB, pc: 4} == execute(state, "4CBB")
  end

  test "5xy0: Skip next instruction if Vx = Vy" do
    state = %State{v2: 0xAB, vC: 0xAB, pc: 2}

    assert %State{v2: 0xAB, vC: 0xAB, pc: 4} == execute(state, "52C0")
  end

  test "6xkk: Puts the value kk into register Vx" do
    state = %State{vC: 0xAB}

    assert %State{vC: 0x88} == execute(state, "6C88")
  end

  test "7xkk: Set Vx = Vx + kk" do
    state = %State{vC: 0xAB}

    assert %State{vC: 0xAB + 0xDE} == execute(state, "7CDE")
  end

  test "8xy0: Set Vx = Vy" do
    state = %State{vC: 0xAB, vD: 0xDE}

    assert %State{vC: 0xAB, vD: 0xAB} == execute(state, "8DC0")
  end

  test "8xy1: Set Vx = Vx OR Vy" do
    state = %State{vC: 0xAB, vD: 0xDE}

    assert %State{vC: 0xAB, vD: 0xDE ||| 0xAB} == execute(state, "8DC1")
  end

  test "8xy2: Set Vx = Vx AND Vy" do
    state = %State{vC: 0xAB, vD: 0xDE}

    assert %State{vC: 0xAB, vD: 0xDE &&& 0xAB} == execute(state, "8DC2")
  end

  test "8xy3: Set Vx = Vx XOR Vy" do
    state = %State{vC: 0xAB, vD: 0xDE}

    assert %State{vC: 0xAB, vD: 0xDE ^^^ 0xAB} == execute(state, "8DC3")
  end

  test "8xy4: Set Vx = Vx + Vy, set VF = carry (with carry)" do
    state = %State{v1: 0xFF, v2: 0x1}

    assert %State{v1: 0x0, v2: 0x1, vF: 1} == execute(state, "8124")
  end

  test "8xy4: Set Vx = Vx + Vy, set VF = carry (without carry)" do
    state = %State{vA: 0x1, vB: 0x2}

    assert %State{vA: 0x3, vB: 0x2, vF: 0} == execute(state, "8AB4")
  end

  test "8xy5: Set Vx = Vx - Vy, set VF = NOT borrow (with borrow)" do
    state = %State{vA: 0x1, vB: 0x2}

    assert %State{vA: 0xFF, vB: 0x2, vF: 0} == execute(state, "8AB5")
  end

  test "8xy5: Set Vx = Vx - Vy, set VF = NOT borrow (without borrow)" do
    state = %State{vA: 0x4, vB: 0x3}

    assert %State{vA: 0x1, vB: 0x3, vF: 1} == execute(state, "8AB5")
  end

  test "8xy6: Set Vx = Vx SHR 1 (even)" do
    state = %State{vA: 0x8}

    assert %State{vA: 0x4, vF: 0} == execute(state, "8AB6")
  end

  test "8xy6: Set Vx = Vx SHR 1 (odd)" do
    state = %State{vA: 0x7}

    assert %State{vA: 0x3, vF: 1} == execute(state, "8AB6")
  end

  # test "Dxyn" do
  #   state = %State{v1: 0x0, v2: 0x0, i: 0, display: Display.new(), memory: Memory.new()}
  #   new_state = execute(state, "D005")
  # end
end

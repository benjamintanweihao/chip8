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

    [instr_1, instr_2 | _] = ROM.load(file_path)

    assert opcode(instr_1, instr_2) == "6A02"
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
    state = %State{v1: 0x0, v2: 0x0, vF: 0, i: 0, display: Display.new(), memory: Memory.new()}

    %State{display: display} =
      state
      |> execute("A005")
      |> execute("D125")
      |> execute("00E0")

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

  test "8xy7: SUBN Vx, Vy (Vy > Vx)" do
    state = %State{vA: 0x4, vB: 0x6}

    assert %State{vA: 0x2, vB: 0x6, vF: 1} == execute(state, "8AB7")
  end

  test "8xy7: SUBN Vx, Vy (Vy < Vx)" do
    state = %State{vA: 0x6, vB: 0x2}

    assert %State{vA: 256 - 0x4, vB: 0x2, vF: 0} == execute(state, "8AB7")
  end

  describe "8xyE: Set Vx = Vx SHL 1" do
    test "0x1 (without significant bit)" do
      assert %State{vA: 0x1 * 2, vF: 0} == execute(%State{vA: 0x1}, "8ABE")
    end

    test "0x11 (without significant bit)" do
      assert %State{vA: 0x11 * 2, vF: 0} == execute(%State{vA: 0x11}, "8ABE")
    end

    test "0xF0 (with significant bit)" do
      assert %State{vA: 0xF0 * 2 - 256, vF: 1} == execute(%State{vA: 0xF0}, "8ABE")
    end
  end

  test "9xy0: SNE Vx, Vy (Vx != Vy)" do
    state = %State{vA: 0x1, vB: 0x2, pc: 6}

    assert %State{vA: 0x1, vB: 0x2, pc: 8} == execute(state, "9AB0")
  end

  test "9xy0: SNE Vx, Vy (Vx == Vy)" do
    state = %State{vA: 0x2, vB: 0x2, pc: 6}

    assert %State{vA: 0x2, vB: 0x2, pc: 6} == execute(state, "9AB0")
  end

  test "Annn: Set I = nnn" do
    assert %State{i: 0xFAB} == execute(%State{}, "AFAB")
  end

  test "Bnnn: Jump to location nnn + v0" do
    assert %State{v0: 0x1, pc: 0xF00 + 0x1} == execute(%State{v0: 0x1}, "BF00")
  end

  test "padded row" do
    assert [1, 1, 1, 1, 0, 0, 0, 0] == padded_row(0xF0)
    assert [1, 0, 0, 1, 0, 0, 0, 0] == padded_row(0x90)
    assert [0, 1, 1, 0, 0, 0, 0, 0] == padded_row(0x60)
  end

  describe "Dxyn: Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision" do
    test "display '0' sprite at (0, 0)" do
      state = %State{i: 0x0, v0: 0, v1: 0, vF: 0, display: Display.new(), memory: Memory.new()}

      %{display: display, vF: vF} = execute(state, "D015")

      assert display[{0, 0}] == 1
      assert display[{1, 0}] == 1
      assert display[{2, 0}] == 1
      assert display[{3, 0}] == 1
      assert display[{4, 0}] == 0

      assert display[{0, 1}] == 1
      assert display[{1, 1}] == 0
      assert display[{2, 1}] == 0
      assert display[{3, 1}] == 1
      assert display[{4, 1}] == 0

      assert display[{0, 2}] == 1
      assert display[{1, 2}] == 0
      assert display[{2, 2}] == 0
      assert display[{3, 2}] == 1
      assert display[{4, 2}] == 0

      assert display[{0, 3}] == 1
      assert display[{1, 3}] == 0
      assert display[{2, 3}] == 0
      assert display[{3, 3}] == 1
      assert display[{4, 3}] == 0

      assert display[{0, 4}] == 1
      assert display[{1, 4}] == 1
      assert display[{2, 4}] == 1
      assert display[{3, 4}] == 1
      assert display[{4, 4}] == 0

      assert vF == 0
    end

    test "display '1' sprite at (0, 0)" do
      state = %State{i: 0x5, v0: 0, v1: 0, vF: 0, display: Display.new(), memory: Memory.new()}

      %{display: display, vF: vF} = execute(state, "D015")

      assert display[{0, 0}] == 0
      assert display[{1, 0}] == 0
      assert display[{2, 0}] == 1
      assert display[{3, 0}] == 0
      assert display[{4, 0}] == 0

      assert display[{0, 1}] == 0
      assert display[{1, 1}] == 1
      assert display[{2, 1}] == 1
      assert display[{3, 1}] == 0
      assert display[{4, 1}] == 0

      assert display[{0, 2}] == 0
      assert display[{1, 2}] == 0
      assert display[{2, 2}] == 1
      assert display[{3, 2}] == 0
      assert display[{4, 2}] == 0

      assert display[{0, 3}] == 0
      assert display[{1, 3}] == 0
      assert display[{2, 3}] == 1
      assert display[{3, 3}] == 0
      assert display[{4, 3}] == 0

      assert display[{0, 4}] == 0
      assert display[{1, 4}] == 1
      assert display[{2, 4}] == 1
      assert display[{3, 4}] == 1
      assert display[{4, 4}] == 0

      assert vF == 0
    end

    test "collision: display 0 then 1" do
      state = %State{v0: 0, v1: 0, vF: 0, display: Display.new(), memory: Memory.new()}
      # Set I to point to '0' sprite
      # Draw '0' sprite
      # Set I to point to '1' sprite
      # Draw '1' sprite
      new_state =
        state
        |> execute("A000")
        |> execute("D015")
        |> execute("A005")
        |> execute("D015")

      assert new_state.vF == 1
    end
  end

  test "Fx07: Set Vx = delay timer value" do
    assert %State{vB: 0xFF, dt: 0xFF} == execute(%State{dt: 0xFF}, "FB07")
  end

  test "Fx15: Set delay timer = Vx" do
    assert %State{vB: 0xFF, dt: 0xFF} == execute(%State{vB: 0xFF}, "FB15")
  end

  test "Fx18: Set sound timer = Vx" do
    assert %State{vB: 0xFF, st: 0xFF} == execute(%State{vB: 0xFF}, "FB18")
  end

  test "Fx1E: Set I = I + Vx" do
    assert %State{vB: 0xFF, i: 0xFF + 0x1} == execute(%State{vB: 0xFF, i: 0x1}, "FB1E")
  end

  describe "Fx29: Set I = location of sprite for digit Vx" do
    test "First sprite" do
      memory = Memory.new()

      assert %State{v1: 0x0, i: 0, memory: memory} ==
               execute(%State{v1: 0x0, memory: memory}, "F129")
    end

    test "Second sprite" do
      memory = Memory.new()

      assert %State{v1: 0x1, i: 5, memory: memory} ==
               execute(%State{v1: 0x1, memory: memory}, "F129")
    end

    test "Last sprite" do
      memory = Memory.new()

      assert %State{v1: 0xF, i: 75, memory: memory} ==
               execute(%State{v1: 0xF, memory: memory}, "F129")
    end
  end

  describe "Fx33: Store BCD representation of Vx in memory locations I, I+1, and I+2." do
    test "135" do
      %State{memory: memory} = execute(%State{v1: 135, memory: Memory.new(), i: 0x200}, "F133")

      assert memory[0x200] == 1
      assert memory[0x200 + 1] == 3
      assert memory[0x200 + 2] == 5
    end

    test "35" do
      %State{memory: memory} = execute(%State{v1: 35, memory: Memory.new(), i: 0x200}, "F133")

      assert memory[0x200] == 0
      assert memory[0x200 + 1] == 3
      assert memory[0x200 + 2] == 5
    end

    test "5" do
      %State{memory: memory} = execute(%State{v1: 5, memory: Memory.new(), i: 0x200}, "F133")

      assert memory[0x200] == 0
      assert memory[0x200 + 1] == 0
      assert memory[0x200 + 2] == 5
    end
  end

  describe "Fx55: Store registers V0 through Vx in memory starting at location I" do
    test "V0 to V2 (V3 is not included)" do
      %State{memory: memory} =
        execute(%State{v0: 0, v1: 1, v2: 2, v3: 3, memory: Memory.new(), i: 0x200}, "F255")

      assert memory[0x200] == 0
      assert memory[0x200 + 1] == 1
      assert memory[0x200 + 2] == 2
      refute memory[0x200 + 3] == 3
    end

    test "V0 to VA" do
      state = %State{
        v0: 0,
        v1: 1,
        v2: 2,
        v3: 3,
        v4: 4,
        v5: 5,
        v6: 6,
        v7: 7,
        v8: 8,
        v9: 9,
        vA: 10,
        memory: Memory.new(),
        i: 0x200
      }

      %State{memory: memory} = execute(state, "FA55")

      assert memory[0x200] == 0
      assert memory[0x200 + 1] == 1
      assert memory[0x200 + 2] == 2
      assert memory[0x200 + 3] == 3
      assert memory[0x200 + 4] == 4
      assert memory[0x200 + 5] == 5
      assert memory[0x200 + 6] == 6
      assert memory[0x200 + 7] == 7
      assert memory[0x200 + 8] == 8
      assert memory[0x200 + 9] == 9
      assert memory[0x200 + 10] == 10
    end
  end

  describe "Fx65: Read registers V0 through Vx from memory starting at location I" do
    test "V0 to V1 (V2 is not included)" do
      memory =
        Memory.new()
        |> Map.replace!(0x200, 0xA)
        |> Map.replace!(0x200 + 1, 0xB)
        |> Map.replace!(0x200 + 2, 0xC)

      new_state = execute(%State{memory: memory, i: 0x200}, "F165")

      assert new_state[:v0] == 0xA
      assert new_state[:v1] == 0xB
      refute new_state[:v2] == 0xC
    end
  end
end

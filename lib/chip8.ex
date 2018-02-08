defmodule Chip8 do
  use GenServer
  use Bitwise

  alias __MODULE__.Memory
  alias __MODULE__.ROM
  alias __MODULE__.Display

  @tick 10

  defmodule State do
    @behaviour Access

    defstruct [
      :v0,
      :v1,
      :v2,
      :v3,
      :v4,
      :v5,
      :v6,
      :v7,
      :v8,
      :v9,
      :vA,
      :vB,
      :vC,
      :vD,
      :vE,
      :vF,
      :i,
      :dt,
      :st,
      :pc,
      :sp,
      :memory,
      :display,
      :stack
    ]

    defdelegate fetch(a, b), to: Map
    defdelegate get(a, b, c), to: Map
    defdelegate get_and_update(a, b, c), to: Map
    defdelegate pop(a, b), to: Map
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    file_path = Path.expand("../roms/pong.rom", __DIR__)
    memory = ROM.load_into_memory(file_path, Memory.new())
    display = Display.new()

    tick()

    {:ok, %State{memory: memory, display: display, stack: [], pc: 0x200}}
  end

  def handle_info(:tick, state) do
    {:ok, opcode} = Map.fetch(state.memory, state.pc)
    new_state = execute(opcode, state)

    tick()

    {:noreply, new_state}
  end

  defp tick do
    Process.send_after(self(), :tick, @tick)
  end

  ###########
  # Opcodes #
  ###########

  ###############################################################################################
  # 00E0 - CLS
  # Clear the display.
  def execute("00E0", state) do
    %{state | display: Display.new()}
  end

  ###############################################################################################
  # 00EE - RET
  # Return from a subroutine.
  #
  # The interpreter sets the program counter to the address at the top of the stack, then
  # subtracts 1 from the stack pointer.
  def execute("00EE", state = %{stack: [top | _], sp: sp}) do
    %{state | pc: top, sp: sp - 1}
  end

  ###############################################################################################
  # 0nnn - SYS addr
  # Jump to a machine code routine at nnn.
  #
  # This instruction is only used on the old computers on which Chip-8 was originally implemented.
  # It is ignored by modern interpreters.
  def execute(<<"0", _rest::size(24)>>, state) do
    state
  end

  ###############################################################################################
  # 1nnn - JP addr
  # Jump to location nnn.
  #
  # The interpreter sets the program counter to nnn.
  def execute(<<"1", n1, n2, n3>>, state) do
    {new_pc, ""} = Integer.parse(<<n1, n2, n3>>, 16)
    %{state | pc: new_pc}
  end

  ###############################################################################################
  # 2nnn - CALL addr
  # Call subroutine at nnn.
  #
  # The interpreter increments the stack pointer, then puts the current PC on the top of the
  # stack. The PC is then set to nnn.
  def execute(<<"2", n1, n2, n3>>, state = %{sp: sp, pc: pc, stack: stack}) do
    {new_pc, ""} = Integer.parse(<<n1, n2, n3>>, 16)

    %{state | sp: sp + 1, stack: [pc | stack], pc: new_pc}
  end

  ###############################################################################################
  # 3xkk - SE Vx, byte
  # Skip next instruction if Vx = kk.
  #
  # The interpreter compares register Vx to kk, and if they are equal, increments the program
  # counter by 2.
  def execute(<<"3", x, k1, k2>>, state = %{pc: pc}) do
    vx = state[String.to_atom("v" <> <<x>>)]
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)

    if vx == kk do
      %{state | pc: pc + 2}
    else
      state
    end
  end

  ###############################################################################################
  # 4xkk - SNE Vx, byte
  # Skip next instruction if Vx != kk.
  #
  # The interpreter compares register Vx to kk, and if they are not equal, increments the program
  # counter by 2.
  def execute(<<"4", x, k1, k2>>, state = %{pc: pc}) do
    vx = state[String.to_atom("v" <> <<x>>)]
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)

    if vx != kk do
      %{state | pc: pc + 2}
    else
      state
    end
  end

  ###############################################################################################
  # 5xy0 - SE Vx, Vy
  # Skip next instruction if Vx = Vy.
  #
  # The interpreter compares register Vx to register Vy, and if they are equal, increments the
  # program counter by 2.
  def execute(<<"5", x, y, "0">>, state = %{pc: pc}) do
    vx = state[String.to_atom("v" <> <<x>>)]
    vy = state[String.to_atom("v" <> <<y>>)]

    if vx == vy do
      %{state | pc: pc + 2}
    else
      state
    end
  end

  ###############################################################################################
  # 6xkk - LD Vx, byte
  # Set Vx = kk.
  #
  # The interpreter puts the value kk into register Vx.
  def execute(<<"6", x, k1, k2>>, state) do
    reg = String.to_atom("v" <> <<x>>)
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)

    Map.replace!(state, reg, kk)
  end

  ###############################################################################################
  # 7xkk - ADD Vx, byte
  # Set Vx = Vx + kk.
  #
  # Adds the value kk to the value of register Vx, then stores the result in Vx.
  def execute(<<"7", x, k1, k2>>, state) do
    reg = String.to_atom("v" <> <<x>>)
    val = state[reg]
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)

    Map.replace!(state, reg, val + kk)
  end

  ###############################################################################################
  # 8xy0 - LD Vx, Vy
  # Set Vx = Vy.
  #
  # Stores the value of register Vy in register Vx.
  def execute(<<"8", x, y, "0">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    Map.replace!(state, vx, state[vy])
  end

  ###############################################################################################
  # 8xy1 - OR Vx, Vy
  # Set Vx = Vx OR Vy.
  #
  # Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx. A bitwise OR
  # compares the corrseponding bits from two values, and if either bit is 1, then the same bit
  # in the result is also 1. Otherwise, it is 0.
  def execute(<<"8", x, y, "1">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    Map.replace!(state, vx, state[vx] ||| state[vy])
  end

  ###############################################################################################
  # 8xy2 - AND Vx, Vy
  # Set Vx = Vx AND Vy.
  #
  # Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx. A bitwise
  # AND compares the corrseponding bits from two values, and if both bits are 1, then the same
  # bit in the result is also 1. Otherwise, it is 0.
  def execute(<<"8", x, y, "2">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    Map.replace!(state, vx, state[vx] &&& state[vy])
  end

  ###############################################################################################
  # 8xy3 - XOR Vx, Vy
  # Set Vx = Vx XOR Vy.
  #
  # Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx.
  # An exclusive OR compares the corrseponding bits from two values, and if the bits are not both
  # the same, then the corresponding bit in the result is set to 1. Otherwise, it is 0.
  def execute(<<"8", x, y, "3">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    Map.replace!(state, vx, state[vx] ^^^ state[vy])
  end

  ###############################################################################################
  # 8xy4 - ADD Vx, Vy
  # Set Vx = Vx + Vy, set VF = carry.
  #
  # The values of Vx and Vy are added together. If the result is greater than 8 bits (i.e., > 255,)
  # VF is set to 1, otherwise 0. Only the lowest 8 bits of the result are kept, and stored in Vx.
  def execute(<<"8", x, y, "4">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)
    add = state[vx] + state[vy]

    %{state | vF: if(add > 255, do: 1, else: 0)} |> Map.replace!(vx, add &&& 0xFF)
  end

  ###############################################################################################
  # 8xy5 - SUB Vx, Vy
  # Set Vx = Vx - Vy, set VF = NOT borrow.
  #
  # If Vx > Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results
  # stored in Vx.
  def execute(<<"8", x, y, "5">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)
    sub = state[vx] - state[vy]

    %{state | vF: if(sub > 0, do: 1, else: 0)} |> Map.replace!(vx, sub)
  end

  ###############################################################################################
  # 8xy6 - SHR Vx {, Vy}
  # Set Vx = Vx SHR 1.
  #
  # If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided
  # by 2.
  def execute(<<"8", x, _y, "6">>, state) do
    vx = String.to_atom("v" <> <<x>>)

    %{state | vF: if(state[vx] &&& 1 == 1, do: 1, else: 0)} |> Map.replace!(vx, div(state[vx], 2))
  end

  ###############################################################################################
  # 8xy7 - SUBN Vx, Vy
  # Set Vx = Vy - Vx, set VF = NOT borrow.
  #
  # If Vy > Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy, and the results
  # stored in Vx.
  def execute(<<"8", x, y, "7">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)
    sub = state[vy] - state[vx]

    %{state | vF: if(sub > 0, do: 1, else: 0)} |> Map.replace!(vx, sub)
  end

  ###############################################################################################
  # 8xyE - SHL Vx {, Vy}
  # Set Vx = Vx SHL 1.
  #
  # If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is
  # multiplied by 2.
  def execute(<<"8", x, _y, "E">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    msb = state[vx] &&& 0x80

    %{state | vF: if(msb == 0x80, do: 1, else: 0)} |> Map.replace!(vx, state[vx] * 2)
  end

  ###############################################################################################
  # 9xy0 - SNE Vx, Vy
  # Skip next instruction if Vx != Vy.
  #
  # The values of Vx and Vy are compared, and if they are not equal, the program counter is
  # increased by 2.
  def execute(<<"9", x, y, "0">>, state = %{pc: pc}) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    %{state | pc: if(state[vx] != state[vy], do: pc + 2, else: pc)}
  end

  ###############################################################################################
  # Annn - LD I, addr
  # Set I = nnn.
  #
  # The value of register I is set to nnn.
  def execute(<<"A", n1, n2, n3>>, state) do
    {new_i, ""} = Integer.parse(<<n1, n2, n3>>, 16)

    %{state | i: new_i}
  end

  ###############################################################################################
  # Bnnn - JP V0, addr
  # Jump to location nnn + V0.
  #
  # The program counter is set to nnn plus the value of V0.
  def execute(<<"B", n1, n2, n3>>, state = %{v0: v0}) do
    {add, ""} = Integer.parse(<<n1, n2, n3>>, 16)

    %{state | pc: add + v0}
  end

  ###############################################################################################
  # Cxkk - RND Vx, byte
  # Set Vx = random byte AND kk.
  #
  # The interpreter generates a random number from 0 to 255, which is then ANDed with the value
  # kk. The results are stored in Vx. See instruction 8xy2 for more information on AND.
  def execute(<<"C", x, k1, k2>>, state) do
    rand = Enum.take_random(0..255, 1) |> hd()
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)
    vx = String.to_atom("v" <> <<x>>)

    Map.replace!(state, vx, rand &&& kk)
  end
end

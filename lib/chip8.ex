defmodule Chip8 do
  use GenServer

  alias __MODULE__.Memory
  alias __MODULE__.ROM
  alias __MODULE__.Display

  @tick 10

  defmodule State do
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
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
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
  defp execute("00E0", state) do
    %{state | display: Display.new()}
  end

  ###############################################################################################
  # 00EE - RET
  # Return from a subroutine.
  #
  # The interpreter sets the program counter to the address at the top of the stack, then
  # subtracts 1 from the stack pointer.
  defp execute("00EE", state = %{stack: [top | _], sp: sp}) do
    %{state | pc: top, sp: sp - 1}
  end

  ###############################################################################################
  # 0nnn - SYS addr
  # Jump to a machine code routine at nnn.
  #
  # This instruction is only used on the old computers on which Chip-8 was originally implemented.
  # It is ignored by modern interpreters.
  defp execute(<<"0", _rest::size(24)>>, state) do
    state
  end

  ###############################################################################################
  # 1nnn - JP addr
  # Jump to location nnn.
  #
  # The interpreter sets the program counter to nnn.
  defp execute(<<"1", n1, n2, n3>>, state) do
    {new_pc, ""} = Integer.parse(<<n1, n2, n3>>, 16)
    %{state | pc: new_pc}
  end

  ###############################################################################################
  # 2nnn - CALL addr
  # Call subroutine at nnn.
  #
  # The interpreter increments the stack pointer, then puts the current PC on the top of the
  # stack. The PC is then set to nnn.
  defp execute(<<"2", n1, n2, n3>>, state = %{sp: sp, pc: pc, stack: stack}) do
    {new_pc, ""} = Integer.parse(<<n1, n2, n3>>, 16)

    %{state | sp: sp + 1, stack: [pc | stack], pc: new_pc}
  end

  ###############################################################################################
  # 3xkk - SE Vx, byte
  # Skip next instruction if Vx = kk.
  #
  # The interpreter compares register Vx to kk, and if they are equal, increments the program
  # counter by 2.
  defp execute(<<"3", x, k1, k2>>, state = %{pc: pc}) do
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
  defp execute(<<"4", x, k1, k2>>, state = %{pc: pc}) do
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
  defp execute(<<"5", x, y, "0">>, state = %{pc: pc}) do
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
  defp execute(<<"6", x, k1, k2>>, state) do
    reg = String.to_atom("v" <> <<x>>)
    {kk, ""} = Integer.parse(<<k1, k2>>, 16)

    Map.replace!(state, reg, kk)
  end

  ###############################################################################################
  # 7xkk - ADD Vx, byte
  # Set Vx = Vx + kk.
  #
  # Adds the value kk to the value of register Vx, then stores the result in Vx.
  defp execute(<<"7", x, k1, k2>>, state) do
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
  defp execute(<<"8", x, y, "0">>, state) do
    vx = String.to_atom("v" <> <<x>>)
    vy = String.to_atom("v" <> <<y>>)

    Map.replace!(state, vx, state[vy])
  end

end

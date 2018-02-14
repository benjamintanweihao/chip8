defmodule Chip8.State do
  @behaviour Access

  alias Chip8.{Display, IO}

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
    :stack,
    :io,
    :renderer,
    :draw?
  ]

  defdelegate fetch(a, b), to: Map
  defdelegate get(a, b, c), to: Map
  defdelegate get_and_update(a, b, c), to: Map
  defdelegate pop(a, b), to: Map

  def new do
    %__MODULE__{
      v0: 0,
      v1: 0,
      v2: 0,
      v3: 0,
      v4: 0,
      v5: 0,
      v6: 0,
      v7: 0,
      v8: 0,
      v9: 0,
      vA: 0,
      vB: 0,
      vC: 0,
      vD: 0,
      vE: 0,
      vF: 0,
      i: 0,
      dt: 0,
      st: 0,
      pc: 0x200,
      sp: 0,
      memory: nil,
      display: Display.new(),
      stack: [],
      io: IO.new(),
      renderer: nil,
      draw?: false
    }
  end
end

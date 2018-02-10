defmodule Chip8.State do
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

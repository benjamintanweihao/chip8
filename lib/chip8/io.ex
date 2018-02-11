defmodule Chip8.IO do
  @behaviour Access

  defstruct [:"1", :"2", :"3", :C, :"4", :"5", :"6", :D, :"7", :"8", :"9", :E, :A, :"0", :B, :F]

  defdelegate fetch(a, b), to: Map
  defdelegate get(a, b, c), to: Map
  defdelegate get_and_update(a, b, c), to: Map
  defdelegate pop(a, b), to: Map

  def new do
    %__MODULE__{
      "1": false,
      "2": false,
      "3": false,
      C: false,
      "4": false,
      "5": false,
      "6": false,
      D: false,
      "7": false,
      "8": false,
      "9": false,
      E: false,
      A: false,
      "0": false,
      B: false,
      F: false
    }
  end
end

defmodule Chip8 do
  use GenServer

  alias __MODULE__.Memory

  defmodule State do
    defstruct [
      :V0,
      :V1,
      :V2,
      :V3,
      :V4,
      :V5,
      :V6,
      :V7,
      :V8,
      :V9,
      :VA,
      :VB,
      :VC,
      :VD,
      :VE,
      :VF,
      :I,
      :DT,
      :ST,
      :PC,
      :SP,
      :memory,
      :display
    ]
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run do
    GenServer.handle_call(__MODULE__, :run)
  end

  def init(opts) do
    # TODO: Initialize memory layout
    # TODO: Load ROM

    {:ok, %State{memory: Memory.new()}}
  end

  def handle_call(:run, _from, state) do
    {:reply, :ok, state}
  end

end

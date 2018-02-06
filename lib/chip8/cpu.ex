defmodule Chip8.CPU do
  defmodule Registers do
    # 8 bits
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
      :SP
    ]
  end
end

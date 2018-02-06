defmodule Chip8Test do
  use ExUnit.Case
  doctest Chip8

  test "greets the world" do
    assert Chip8.hello() == :world
  end
end

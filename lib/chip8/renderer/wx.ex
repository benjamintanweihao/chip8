defmodule Chip8.Renderer.Wx do
  @behaviour Chip8.Renderer

  use GenServer
  use Bitwise
  require Logger

  @cell_size 10
  @board_size %{
    x: 64,
    y: 32
  }

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    wx = :wx.new()

    frame =
      :wxFrame.new(
        wx,
        -1,
        "CHIP 8",
        size: {@board_size.x * @cell_size, @board_size.y * @cell_size}
      )

    panel = :wxPanel.new(frame)
    :wxFrame.show(frame)

    for evt <- [:char, :key_down, :key_up, :close_window] do
      :ok = :wxFrame.connect(panel, evt)
    end

    {:ok, %{panel: panel}}
  end

  def render(display) do
    GenServer.call(__MODULE__, {:render, display})
  end

  def handle_call({:render, display}, _from, state) do
    do_render(display, state)

    {:reply, :ok, state}
  end

  def handle_info({:wx, _, _, _, {:wxKey, :char, _, _, key_char, _, _, _, _, _, _, _, _}}, state) do
    Logger.info("Char: #{key_char} #{<<key_char>>}")

    {:noreply, state}
  end

  def handle_info(
        {:wx, _, _, _, {:wxKey, :key_up, _, _, key_char, _, _, _, _, _, _, _, _}},
        state
      ) do
    Logger.info("Key Up: #{key_char} #{<<key_char>>}")

    {:noreply, state}
  end

  def handle_info(
        {:wx, _, _, _, {:wxKey, :key_down, _, _, key_char, _, _, _, _, _, _, _, _}},
        state
      ) do
    Logger.info("Key Down: #{key_char} #{<<key_char>>}")

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled: #{msg}")

    {:noreply, state}
  end

  defp do_render(display, %{panel: panel}) do
    dc = :wxPaintDC.new(panel)
    pen = :wxPen.new({0, 0, 0, 255})
    canvas = :wxGraphicsContext.create(dc)

    :wxGraphicsContext.setPen(canvas, pen)

    draw_board(canvas, display)

    :wxPaintDC.destroy(dc)
  end

  defp draw_board(canvas, display) do
    for y <- 0..(@board_size.y - 1) do
      for x <- 0..(@board_size.x - 1) do
        draw_square(canvas, x, y, brush_for(Map.fetch!(display, {x, y})))
      end
    end
  end

  defp draw_square(canvas, x, y, brush) do
    :wxGraphicsContext.setBrush(canvas, brush)
    true_x = @cell_size * x
    true_y = @cell_size * y
    :wxGraphicsContext.drawRectangle(canvas, true_x, true_y, @cell_size, @cell_size)
  end

  # Green
  defp brush_for(1), do: :wxBrush.new({0, 255, 0, 255})
  # Black
  defp brush_for(0), do: :wxBrush.new({0, 0, 0, 255})
end

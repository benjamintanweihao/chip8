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

  def start_link(game) do
    # GenServer.start_link(__MODULE__, game, name: __MODULE__)
    {:wx_ref, 35, :wxFrame, pid} = :wx_object.start_link(__MODULE__, game, [])
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  def init(game) do
    wx = :wx.new()

    frame =
      :wxFrame.new(
        wx,
        -1,
        "CHIP 8",
        size: {@board_size.x * @cell_size, @board_size.y * @cell_size}
      )

    panel = :wxPanel.new(frame)
    :wxPanel.setBackgroundColour(panel, black())
    :wxPanel.connect(panel, :paint, [:callback])

    for evt <- [:char, :key_down, :key_up, :close_window] do
      :ok = :wxFrame.connect(panel, evt)
    end

    :wxFrame.show(frame)

    {frame, %{game: game, panel: panel}}
  end

  def render(prev_display, new_display) do
    GenServer.call(__MODULE__, {:render, prev_display, new_display})
  end

  def handle_call({:render, prev_display, new_display}, _from, state) do
    do_render(prev_display, new_display, state)

    {:reply, :ok, state}
  end

  def handle_event(
        {:wx, _, _, _, {:wxKey, :char, _, _, key_char, _, _, _, _, _, _, _, _}},
        %{game: game} = state
      ) do
    Logger.info("Char: #{key_char} #{<<key_char>>}")
    send(game, {:char, map_key(<<key_char>>)})

    {:noreply, state}
  end

  def handle_event(
        {:wx, _, _, _, {:wxKey, :key_up, _, _, key_char, _, _, _, _, _, _, _, _}},
        %{game: game} = state
      ) do
    Logger.info("Key Up: #{key_char} #{<<key_char>>}")
    send(game, {:key_up, map_key(<<key_char>>)})

    {:noreply, state}
  end

  def handle_event(
        {:wx, _, _, _, {:wxKey, :key_down, _, _, key_char, _, _, _, _, _, _, _, _}},
        %{game: game} = state
      ) do
    Logger.info("Key Down: #{key_char} #{<<key_char>>}")
    send(game, {:key_down, map_key(<<key_char>>)})

    {:noreply, state}
  end

  def handle_sync_event({:wx, _, panel, [], {:wxPaint, :paint}}, _, state) do
    :ok
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled: #{msg}")

    {:noreply, state}
  end

  defp do_render(prev_display, new_display, %{panel: panel}) do
    dc = :wxPaintDC.new(panel)
    pen = :wxPen.new({0, 0, 0, 255})
    canvas = :wxGraphicsContext.create(dc)

    :wxGraphicsContext.setPen(canvas, pen)

    draw_board(canvas, prev_display, new_display)

    :wxPaintDC.destroy(dc)
  end

  defp draw_board(canvas, prev_display, new_display) do
    for y <- 0..(@board_size.y - 1) do
      for x <- 0..(@board_size.x - 1) do
        old_pixel = Map.fetch!(prev_display, {x, y})
        new_pixel = Map.fetch!(new_display, {x, y})
        # Make sure that we really need to paint this pixel
        if old_pixel != new_pixel do
          draw_square(canvas, x, y, brush_for(new_pixel))
        end
      end
    end
  end

  defp draw_square(canvas, x, y, brush) do
    :wxGraphicsContext.setBrush(canvas, brush)
    true_x = @cell_size * x
    true_y = @cell_size * y
    :wxGraphicsContext.drawRectangle(canvas, true_x, true_y, @cell_size, @cell_size)
  end

  defp black, do: {0, 0, 0, 255}

  # Green
  defp brush_for(1), do: :wxBrush.new({0, 255, 0, 255})
  # Black
  defp brush_for(0), do: :wxBrush.new(black())

  defp map_key("1"), do: "1"
  defp map_key("2"), do: "2"
  defp map_key("3"), do: "3"
  defp map_key("4"), do: "C"
  defp map_key("Q"), do: "4"
  defp map_key("W"), do: "5"
  defp map_key("E"), do: "6"
  defp map_key("R"), do: "D"
  defp map_key("A"), do: "7"
  defp map_key("S"), do: "8"
  defp map_key("D"), do: "9"
  defp map_key("F"), do: "E"
  defp map_key("Z"), do: "A"
  defp map_key("X"), do: "0"
  defp map_key("C"), do: "B"
  defp map_key("V"), do: "F"

  defp map_key(key) do
    Logger.warn("Unhandled key: #{key}")
    key
  end
end

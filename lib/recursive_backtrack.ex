defmodule RecursiveBacktrack do
  require Bitwise

  def run(width \\ 10, height \\ 10) do
    IO.write "\e[2J" # clear the screen
    grid = 0..(height - 1) |> Enum.map(fn _y ->
      0..(width - 1) |> Enum.map(fn _x ->
        0
      end)
    end)
    carve_passages_from(0, 0, grid) |> print
  end

  def directions do
    %{
      n: {1, 0, -1},
      s: {2, 0, 1},
      e: {4, 1, 0},
      w: {8, -1, 0}
    }
  end

  def opposite({card, _}) do
    opp = case card do
      :n -> :s
      :s -> :n
      :w -> :e
      :e -> :w
    end
    {:ok, {bw, _, _}} = Map.fetch(directions, opp)
    bw
  end

  def carve_passages_from(cx, cy, grid) do
    directions
    |> Enum.shuffle
    |> Enum.reduce(grid, fn {_card, {bw, dx, dy}} = direction, grid ->
      nx = cx + dx
      ny = cy + dy
      current_row = Enum.at(grid, cy)
      current_cell = Enum.at(current_row, cx)
      other_row = Enum.at(grid, ny)
      if other_row do
        other_cell = Enum.at(other_row, nx)
        if ny in 0..(length(grid) - 1) and nx in 0..(length(other_row) - 1) and other_cell == 0 do
          current_cell = Bitwise.bor(current_cell, bw)
          other_cell = Bitwise.bor(other_cell, opposite(direction))
          current_row = List.replace_at(current_row, cx, current_cell)
          grid = List.replace_at(grid, cy, current_row)
          other_row = Enum.at(grid, ny) # get it again, might be the same row and changed
          other_row = List.replace_at(other_row, nx, other_cell)
          grid = List.replace_at(grid, ny, other_row)
          print(grid)
          :timer.sleep(25)
          grid = carve_passages_from(nx, ny, grid)
        end
      end
      grid
    end)
  end

  def print(grid) do
    IO.write "\e[H" # move to upper-left
    IO.write " "
    1..(length(Enum.at(grid, 0)) * 2 - 1) |> Enum.each(fn _n ->
      IO.write "_"
    end)
    IO.puts " "
    Enum.each(grid, fn row ->
      IO.write "|"
      row
      |> Enum.with_index
      |> Enum.each(fn {cell, x} ->
        if Bitwise.band(cell, 2) != 0 do
          IO.write " " # open to the south
        else
          IO.write "_" # not open to the south
        end
        if Bitwise.band(cell, 4) != 0 do
          # open to the east
          next_cell = Enum.at(row, x + 1)
          what = Bitwise.bor(cell, next_cell) |> Bitwise.band(2)
          if what != 0 do
            IO.write " "
          else
            IO.write "_"
          end
        else
          IO.write "|" # not open to the east
        end
      end)
      IO.puts ""
    end)
  end

end

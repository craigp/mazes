defmodule GrowingTree do
  require Bitwise

  def run(width \\ 10, height \\ 10) do
    grid = 0..(height - 1) |> Enum.map(fn _y ->
      0..(width - 1) |> Enum.map(fn _x ->
        0
      end)
    end)
    carve_passages(width, height, grid)
  end

  def opposite({card, _}) do
    opp = case card do
      :n -> :s
      :s -> :n
      :w -> :e
      :e -> :w
    end
    {:ok, {bw, _, _}} = Map.fetch(get_directions, opp)
    bw
  end

  def get_directions do
    %{
      n: {1, 0, -1},
      s: {2, 0, 1},
      e: {4, 1, 0},
      w: {8, -1, 0}
    }
  end

  def carve_passages(width, height, grid) do
    IO.write "\e[2J" # clear the screen
    x = Enum.random(0..(width - 1))
    y = Enum.random(0..(height - 1))
    cells = [{x, y}]
    carve_cells(grid, cells)
  end

  def update_cell(grid, x, y, bw) do
    row = Enum.at(grid, y)
    cell = Enum.at(row, x)
    cell = Bitwise.bor(cell, bw)
    row = List.replace_at(row, x, cell)
    List.replace_at(grid, y, row)
  end

  def carve_cells(grid, cells) when length(cells) > 0 do
    directions =
      get_directions
      |> Enum.shuffle
    carve_cells(grid, cells, directions)
  end

  def carve_cells(grid, _cells) do
    print(grid)
  end

  def carve_cells(grid, cells, directions) do
    cell = List.first(cells)
    carve_cells(grid, cells, cell, directions)
  end

  def carve_cells(grid, cells, cell, directions) when length(directions) > 0 do
    key = directions |> Keyword.keys |> List.first
    {direction, directions} = Keyword.pop(directions, key)
    carve_cells(grid, cells, cell, directions, {key, direction})
  end

  def carve_cells(grid, cells, _cell, _directions) do
    [_removed|updated_cells] = cells
    carve_cells(grid, updated_cells)
  end

  def carve_cells(grid, cells, {x, y} = cell, directions, {card, {bw, dx, dy}} = direction) when length(cells) > 0 do
    nx = x + dx
    ny = y + dy
    row = Enum.at(grid, ny)
    if row do
      grid_cell = Enum.at(row, nx)
      if ny in 0..(length(grid) - 1) and nx in 0..(length(row) - 1) and grid_cell == 0 do
        grid =
          grid
          |> update_cell(x, y, bw)
          |> update_cell(nx, ny, opposite(direction))
        print(grid)
        :timer.sleep(25)
        cells = [{nx, ny}|cells]
        carve_cells(grid, cells)
      else
        carve_cells(grid, cells, cell, directions)
      end
    else
      carve_cells(grid, cells, cell, directions)
    end
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

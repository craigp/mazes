defmodule GrowingTree do
  use Bitwise

  @north 1
  @south 2
  @east 4
  @west 8

  def run(width \\ 10, height \\ 10) do
    # build a square grid of zeros (indicating no bitflags set, ie. not open in
    # any direction yet)
    0..(height - 1) |> Enum.map(fn _y ->
      0..(width - 1) |> Enum.map(fn _x ->
        0
      end)
    end) |> carve_passages(width, height)
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
    # simple direction map - the key is the cardinal direction, the first element
    # of the tuple is a unique bitflag, the following two elements are the x/y
    # adjustment to move in that direction
    %{
      n: {@north, 0, -1},
      s: {@south, 0, 1},
      e: {@east, 1, 0},
      w: {@west, -1, 0}
    }
  end

  def carve_passages(grid, width, height) do
    IO.write "\e[2J" # clear the screen
    # pick a random x/y starting position in the grid of zeros
    x = Enum.random(0..(width - 1))
    y = Enum.random(0..(height - 1))
    cells = [{x, y}]
    carve_cells(grid, cells)
  end

  def update_cell(grid, x, y, bw) do
    # get the row and cell at the x/y coords
    row = Enum.at(grid, y)
    cell =
      row
      |> Enum.at(x)
      |> Bitwise.bor(bw) # mark the cell as open in the direction specified
    updated_row = List.replace_at(row, x, cell)
    List.replace_at(grid, y, updated_row)
  end

  def carve_cells(grid, cells) when length(cells) > 0 do
    # grab a copy of the directions and shuffle them to add an element of
    # randomness to movements
    directions =
      get_directions
      |> Enum.shuffle
    carve_cells(grid, cells, directions)
  end

  def carve_cells(grid, _cells) do
    print(grid)
  end

  def carve_cells(grid, cells, directions) do
    # grab the first x/y cell from the list and pass it seperately from the rest
    cell = List.first(cells)
    carve_cells(grid, cells, cell, directions)
  end

  def carve_cells(grid, cells, cell, directions) when length(directions) > 0 do
    # grab the first direction from the shuffled list and split it up, pass it
    # as a key/value seperate from the rest of the directions
    key =
      directions
      |> Keyword.keys
      |> List.first
    {direction, directions} = Keyword.pop(directions, key)
    carve_cells(grid, cells, cell, directions, {key, direction})
  end

  def carve_cells(grid, [_|updated_cells], _cell, _directions) do
    # if we've used all the directions then remove the first cell and start again
    carve_cells(grid, updated_cells)
  end

  def carve_cells(grid, cells, {x, y} = cell, directions, {card, {bw, dx, dy}} = direction) when length(cells) > 0 do
    # get the new x/y position after this movement
    nx = x + dx
    ny = y + dy
    # get the row of values for the y axis value in the direction we're moving
    case Enum.at(grid, ny) do
      nil ->
        # the row doesn't exist, we've moved as far as we can in that direction,
        # so try the next direction
        carve_cells(grid, cells, cell, directions)
      row ->
        # if this row exists then grab the cell at this x axis value
        grid_cell = Enum.at(row, nx)
        # check that this y value is not at the very edge of the grid, and that the
        # cell value is zero (it hasn't been carved out yet)
        cond do
          ny in 0..(length(grid) - 1) and nx in 0..(length(row) - 1) and grid_cell == 0 ->
            updated_grid =
              grid
              |> update_cell(x, y, bw) # mark the cell as open in this direction
              |> update_cell(nx, ny, opposite(direction)) # ..and in the opposite direction
            print(updated_grid)
            :timer.sleep(25)
            # shift the next cell (in the direction we were moving) onto the cells list
            cells = [{nx, ny}|cells]
            # this movement was successful, so start at the beginning again using a
            # newly randomised direction
            carve_cells(updated_grid, cells)
          true ->
            # this row would be at the edge of the grid, we've moved as far as we
            # can in that direction, so try in the next direction
            carve_cells(grid, cells, cell, directions)
        end
    end
  end

  def print(grid) do
    # move to upper-left
    IO.write "\e[H"
     # print the top edge of the grid, since we will never allow a cell to be
     # open to the north at the top edge of the grid
    IO.write " "
    1..(length(Enum.at(grid, 0)) * 2 - 1) |> Enum.each(fn _n ->
      IO.write "_"
    end)
    IO.puts " "
    # draw the actual grid, row by row
    Enum.each(grid, fn row ->
      # as above, cannot be open at the edge so can safely draw the far west
      # wall of each row
      IO.write "|"
      row
      |> Enum.with_index
      |> Enum.each(fn {cell, x} ->
        # if it's open to the south we assume it's open to the north as well, we've
        # drawn the top border, and since it will never be open to the south at the
        # bottom edge of the grid, we can safely assume that this will draw the bottom
        # edge border when we get to the last row
        cond do
          Bitwise.band(cell, @south) != 0 ->
            # open to the south
            IO.write " "
          true ->
            # not open to the south
            IO.write "_"
        end
        cond do
          Bitwise.band(cell, @east) != 0 ->
            # open to the east, so get the cell immediately east of this one
            next_cell = Enum.at(row, x + 1)
            # this is tricky, we're not drawing the cell, we're drawing the border
            # between this cell and it's eastern neighbour - if either of these
            # cells is open to the south we want to put a space, but if neither of
            # them are then we want to draw an underscore - so we bitwise OR them
            # together and then bitwise AND them to the bitflag for south (2)
            cell
            |> Bitwise.bor(next_cell)
            |> Bitwise.band(@south)
            |> case do
              0 -> "_"
              _ -> " "
            end
            |> IO.write
          true ->
            # not open to the east
            IO.write "|"
        end
      end)
      IO.puts ""
    end)
  end

end

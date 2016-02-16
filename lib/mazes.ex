defmodule Mazes do

  def main(args) do
    run(args)
  end

  def run([type, width, height]) do
    width = String.to_integer(width)
    height = String.to_integer(height)
    case type do
      "grow" ->
        GrowingTree.run(width, height)
      "recurse" ->
        RecursiveBacktrack.run(width, height)
      _ ->
        GrowingTree.run(width, height)
    end
  end

  def run([width, height]) do
    width = String.to_integer(width)
    height = String.to_integer(height)
    GrowingTree.run(width, height)
  end

end

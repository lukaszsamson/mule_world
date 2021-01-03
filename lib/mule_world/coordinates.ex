defmodule MuleWorld.Coordinates do
  require Record

  Record.defrecord(:coordinates, x: 0, y: 0)
  @type t :: record(:coordinates, x: non_neg_integer, y: non_neg_integer)

  def move(coordinates(x: x, y: y), :up), do: coordinates(x: x, y: y - 1)
  def move(coordinates(x: x, y: y), :down), do: coordinates(x: x, y: y + 1)
  def move(coordinates(x: x, y: y), :left), do: coordinates(x: x - 1, y: y)
  def move(coordinates(x: x, y: y), :right), do: coordinates(x: x + 1, y: y)
end

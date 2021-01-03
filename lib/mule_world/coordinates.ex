defmodule MuleWorld.Coordinates do
  require Record

  Record.defrecord(:coordinates, x: 0, y: 0)
  @type t :: record(:coordinates, x: non_neg_integer, y: non_neg_integer)
end

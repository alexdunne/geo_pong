defmodule GeoPong.GameInstances.Ball do
  alias GeoPong.GameInstances.Ball

  @enforce_keys [:x, :y, :x_speed, :y_speed]
  defstruct [:x, :y, :x_speed, :y_speed]

  def new(opts) do
    struct!(Ball, opts)
  end
end

defmodule Repo do
  defstruct [:topic, :show?, :name, :href, :description, stars: -777, time: -1]
end

defmodule StarsTime do
  defstruct [:href, :stars, time: -1]
end

defmodule Utils do

  def str_to_int_def(strAsNumber, default \\ 0) do
    case strAsNumber do
      nil -> default
      _ ->
        case Integer.parse(strAsNumber) do
          :error -> default
          {number, _} -> number
        end
    end
  end

end

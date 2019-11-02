defmodule Utils do

  def get_stars_time_ok_status(list) do
    list1 = Enum.filter(list, fn {x, _} -> x == :ok end)
    Enum.map(list1, fn {_, x} -> x end)
  end

  def str_to_int_def(strAsNumber) do
    case strAsNumber do
      nil -> 0
        _ -> case Integer.parse(strAsNumber) do
               :error -> 0
               {number, _} -> number
             end
    end
  end

end

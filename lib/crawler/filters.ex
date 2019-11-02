defmodule Filters do

  def order(entries) do
    Enum.sort(entries, fn(%Repo{topic: topic1, name: name1}, %Repo{topic: topic2, name: name2}) ->  topic1 <> String.downcase(name1) <= topic2 <> String.downcase(name2) end)
  end

 def insert_topics(entries) do
   itf(entries, nil, [])
 end

 defp itf([%Repo{topic: topic} = head | tail], curr_topic, acc) do
   if curr_topic == topic do
     itf(tail, curr_topic, [head | acc])
   else
    itf(tail, topic, [head | [ %Repo{topic: topic, show?: true} | acc]])
   end
 end

 defp itf([], _curr_topic, acc) do
  Enum.reverse(acc)
 end

end

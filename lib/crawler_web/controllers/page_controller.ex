defmodule CrawlerWeb.PageController do
  use CrawlerWeb, :controller

  def index(conn, _params) do
    min_stars_str = conn.query_params["min_stars"]
    min_stars = Utils.str_to_int_def(min_stars_str)
    contents = Storage.get_data(min_stars)
      |> Enum.map(fn {_key, value} -> value end)
      |> Enum.sort(fn(%Repo{topic: topic1, name: name1}, %Repo{topic: topic2, name: name2}) ->  topic1 <> String.downcase(name1) <= topic2 <> String.downcase(name2) end)
      |> insert_topics()
    case contents do
      [] -> render(conn, "myindex.html")
       _ -> render(conn, "index.html",  contents: contents)
    end
  end


  defp insert_topics(entries) do
    insert_topics(entries, nil, [])
  end

  defp insert_topics([%Repo{topic: topic} = head | tail], curr_topic, acc) do
    if curr_topic == topic do
      insert_topics(tail, curr_topic, [head | acc])
    else
     insert_topics(tail, topic, [head | [ %Repo{topic: topic, show?: true} | acc]])
    end
  end

  defp insert_topics([], _curr_topic, acc) do
   Enum.reverse(acc)
  end

end

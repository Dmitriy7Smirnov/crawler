defmodule CrawlerWeb.PageController do
  use CrawlerWeb, :controller

  def index(conn, _params) do
    min_stars_str = conn.query_params["min_stars"]
    min_stars = Utils.str_to_int_def(min_stars_str)
    contents = Storage.get_repos(min_stars)
      |> Enum.map(fn {_key, value} -> value end)
      |> Enum.sort(fn(%Repo{topic: topic1, name: name1}, %Repo{topic: topic2, name: name2}) ->  topic1 <> String.downcase(name1) <= topic2 <> String.downcase(name2) end)
    case contents do
      [] -> render(conn, "myindex.html")
       _ -> render(conn, "index.html",  contents: contents, curr_topic: "")
    end
  end

end

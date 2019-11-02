defmodule CrawlerWeb.PageController do
  use CrawlerWeb, :controller

  def index(conn, _params) do
    min_stars_str = conn.query_params["min_stars"]
    min_stars = Utils.str_to_int_def(min_stars_str)
    contents0 = Storage.get_data(min_stars)
    contents = Enum.map(contents0, fn {_key, value} -> value end)
    contents = Filters.order(contents)
    contents = Filters.insert_topics(contents)
    case contents do
      [] -> render(conn, "myindex.html")
       _ -> render(conn, "index.html",  contents: contents)
    end
  end
end

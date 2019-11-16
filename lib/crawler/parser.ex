defmodule Parser do
  require Logger
  def get_repos do
    {:ok, {{_version, 200, _reasonPhrase}, _headers, body}} = :httpc.request(:get, {'https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md', []}, [], [])
    answer = String.split(:erlang.list_to_binary(body), "\n")
    parse(answer, nil, [])
  end

  defp parse([], _topic, repoResultList) do
    Enum.filter(repoResultList, fn elem_repo_or_false -> elem_repo_or_false end) |> Enum.reverse()
  end

  defp parse([head | tail], topic, repoResultList) do
    case topic_string?(head) do
      true
        ->
          case get_topic(head) do
            "Books" -> parse([], topic, repoResultList)
            _ -> parse(tail, get_topic(head), repoResultList)
          end
      false
        ->
          case ref_string?(head) do
            true
              ->
                case get_params(topic, head) do
                  false -> parse(tail, topic, repoResultList)
                  _ -> parse(tail, topic, [get_params(topic, head) | repoResultList])
                end
            false -> parse(tail, topic, repoResultList)
          end
    end
  end

  defp topic_string?(str) do
    regexp = "^(##)"
    case :re.run(str, regexp) do
      :nomatch -> false
      {:match, _} -> true
    end
  end

  defp ref_string?(str) do
    case Regex.run(~r/\((.*github\.com.*)\)/, str) do
      [ _, _href] -> true
                _ -> false
    end
  end

  defp get_topic(str) do
    #str = "## Cloud Infrastructure and Management"
    case String.split(str, "## ") do
      [_, topic] -> topic
               _ -> false
    end
  end

  defp get_params(topic, str) do
    #str = "* [Awesome Erlang](https://gitafhub.com/drobakowski/awesome-erlang) - A curated list of awesome Erlang libraries, resources and shiny things."
    name = case Regex.run(~r/\[(.*)\]/U, str) do
      [ _, name] -> name
      _ -> false
    end
    href = case Regex.run(~r/\((.*github\.com.*)\)/U, str) do
      [ _, href] -> href
      _ -> false
    end
    description = case Regex.run(~r/( - .*$)/, str) do
      [ _, description] -> description
      _ -> false
    end
    if topic && name && href && description do
      %Repo{topic: topic, name: name, href: href, description: description}
    else
      false
    end
  end

  def get_stars_time_struct(_repo_struct = %Repo{href: url_str}) do
    with {:ok, body} <- get_site_body(url_str),
      {:ok, stars} <- get_stars(body, url_str),
      {:ok, datetime_iso8601} <- get_time(body, url_str),
      {:ok, days_ago} <- get_days_ago(datetime_iso8601) do
      {:ok, %StarsTime{href: url_str, stars: stars, time: days_ago}}
    end
  end

  defp get_site_body(url_str) do
    clear_ref = String.replace(url_str, ".git", "")
    url = to_charlist(clear_ref)
    case :httpc.request(:get, {url, []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, _status, _reasonPhrase}, _headers, body}} -> {:ok, body}
      smth
        ->
          Logger.error("can't get site content, got from site: " <> smth <> " " <> url_str)
          {:error, smth}
    end
  end

  defp get_stars(body, url_str) do
    case Floki.find(body, "a.social-count.js-social-count") |> Floki.attribute("aria-label") do
      [numAsText | _tail] -> get_number_from_text(numAsText, url_str)
      _
        ->
          numAsText1 = Floki.find(body, "a.social-count.js-social-count") |> Floki.text
          get_number_from_text(numAsText1, url_str)
    end
  end

  defp get_number_from_text(text, url_str) do
    case Regex.run(~r/(\d+)/, text) do
      [ _, number_str]
        ->
          number =  String.to_integer(number_str)
          {:ok, number}
      smth
        ->
          Logger.error( "can't parse number, got text for parsing: " <> text <> " " <> url_str)
          {:error, smth}
    end
  end

  defp get_time(body, url_str) do
    case Floki.find(body, "div.no-wrap.d-flex.flex-self-start.flex-items-baseline") |> Floki.find("relative-time") |> Floki.attribute("datetime") do
      []
        ->
          url_str1 = url_str <> "/commits"
          get_time2(url_str1)
      [datetime] -> {:ok, datetime}
      smth -> {:error, smth}
    end
  end

  defp get_time2(url_str) do
    case get_site_body(url_str) do
      {:ok, body}
        ->
          case Floki.find(body, "relative-time.no-wrap") |> Floki.attribute("datetime") do
            []
              ->Logger.error("Can't get time2" <> " " <> url_str)
                {:error, "Can't get time2"}
            dates
              ->
                lastDate = Enum.max(dates)
                {:ok, lastDate}
          end
      {:error, reason}
        ->
          Logger.error(reason <> " " <> url_str)
          {:error, reason}
    end
  end

defp get_days_ago(datetime_iso8601) do
  case DateTime.from_iso8601(datetime_iso8601) do
    {:ok, datetime_utc, _}
      ->
        delta = (DateTime.utc_now() |> DateTime.to_unix()) - DateTime.to_unix(datetime_utc)
        {:ok, div(delta, 86400)}
    smth -> {:error, smth}
  end
end

end

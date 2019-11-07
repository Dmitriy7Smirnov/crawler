defmodule Parser do
  require Logger
  def get_content do
    {:ok, {{_version, 200, _reasonPhrase}, _headers, body}} = :httpc.request(:get, {'https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md', []}, [], [])
    answer = String.split(:erlang.list_to_binary(body), "\n")
    parse(answer, nil, [])
  end
  def get_stars do
    url = 'https://github.com/rozap/exquery'
    {:ok, {{_version, 200, _reasonPhrase}, _headers, body}} = :httpc.request(:get, {url, []}, [], [])
    #str = "aria-label=\"31 users starred this repository\">"
    starsStr = case Regex.run(~r/(".* users starred this repository">)/, :erlang.list_to_binary(body)) do
      [ _, starsStr] -> starsStr
      _ -> false
    end
    stars = case Regex.run(~r/(\d+)/, starsStr) do
      [ _, stars] -> stars
      _ -> false
    end
    stars
  end
  def get_stars_floki(rs) do
    clear_ref = String.replace(rs.href, ".git", "")
    url = to_charlist(clear_ref)
    #url = 'https://github.com/erlang/docker-erlang-otp'
    {_status, stars, time} = case :httpc.request(:get, {url, []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, _status, _reasonPhrase}, _headers, body}} -> case get_stars(body, rs) do
                                                                        {:ok, -444} -> Logger.log(:error, "got from site: " <> " " <> rs.href)
                                                                                       {:ok, -1001, -1002}
                                                                        {:ok, stars} ->  case  get_time(body, rs) do
                                                                                         {:ok, datetime} -> {:ok, stars, get_hours_ago(datetime)}
                                                                                         # {:error, _reason} -> {:error, -888, -888}
                                                                                       end
                                                                         #error ->  Logger.log(:error, "got from site: " <> error <> " " <> rs.href)
                                                                         #          {:error, -888, -888}
                                                                     end
      smth -> Logger.log(:error, "can't get site content, got from site: " <> smth <> " " <> rs.href)
              {:error, -555, -1}
    end
    %StarsTime{href: rs.href, stars: stars, time: time}
  end

  def get_stars(body, rs) do
    case Floki.find(body, "a.social-count.js-social-count") |> Floki.attribute("aria-label") do
      [numAsText | _tail] -> stars = get_number_from_text(numAsText, rs.href)
                             {:ok, stars}
      _-> numAsText1 = Floki.find(body, "a.social-count.js-social-count") |> Floki.text
          stars = get_number_from_text(numAsText1, rs.href)
          {:ok, stars}
    end
  end

  def get_time(body, rs) do
    datetime = case Floki.find(body, "div.no-wrap.d-flex.flex-self-start.flex-items-baseline") |> Floki.find("relative-time") |> Floki.attribute("datetime") do
                 [] -> str_url = rs.href <> "/commits"
                url = to_charlist(str_url)
                #IO.inspect url
                case get_time2(url, rs) do
                  {:ok, datetime} -> datetime
                  {:error, reason} -> reason
                end
                [datetime] -> datetime
                smth -> smth
               end
    {:ok, datetime}
  end

  defp get_number_from_text(text, url) do
    stars = case Regex.run(~r/(\d+)/, text) do
              [ _, stars] -> String.to_integer(stars)
              _ -> Logger.log(:error, "can't parse number, got text for parsing: " <> text <> " " <> url)
                   -444
            end
    stars
  end

  def get_time2(url, _rs) do
    case :httpc.request(:get, {url, []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, 200, _reasonPhrase}, _headers, body}} -> dates1 = Floki.find(body, "relative-time.no-wrap") |> Floki.attribute("datetime")
                                                                #IO.inspect dates1
                                                                lastDate = Enum.max(dates1)
                                                                #  IO.inspect lastDate
                                                                {:ok, lastDate}
      error -> Logger.info (error <> " " <> url)
               {:error, :reason}

    end
  end

def get_hours_ago(datetime) do
  {:ok, datetime_u, _} = DateTime.from_iso8601(datetime)
  delta = (DateTime.utc_now() |> DateTime.to_unix()) - DateTime.to_unix(datetime_u)
  div(delta, 86400)
end

  def parse([head | tail], topic, resultList) do
      case topic_string?(head) do
        true -> case get_topic(head) do
                  "Books" -> parse([], topic, resultList)
                       _ -> parse(tail, get_topic(head), resultList)
                end
        false -> case ref_string?(head) do
                     true -> case get_params(topic, head) do
                          false -> parse(tail, topic, resultList)
                              _ -> parse(tail, topic, [get_params(topic, head) | resultList])
                             end
                     false -> parse(tail, topic, resultList)
                 end
      end
  end

  def parse([], _topic, resultList) do
    Enum.reverse(resultList)
  end
  def topic_string?(str) do
    regexp = "^(##)"
    case :re.run(str, regexp) do
      :nomatch -> false
      {:match, _} -> true
    end
  end
  def ref_string?(str) do
    case Regex.run(~r/\((.*github\.com.*)\)/, str) do
      [ _, _href] -> true
                _ -> false
    end
  end
  def get_topic(str) do
    #str = "## Cloud Infrastructure and Management"
    case String.split(str, "## ") do
      [_, topic] -> topic
               _ -> false
    end
  end
  def get_params(topic, str) do
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
      %Repo{topic: topic, show?: false, name: name, href: href, description: description}
    else
      false
    end
  end

end

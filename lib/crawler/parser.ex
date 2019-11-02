defmodule Parser do
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
    url = to_charlist(rs.href)
    #url = 'https://github.com/erlang/docker-erlang-otp'
    stars = case :httpc.request(:get, {url, []}, [], [{:body_format, :binary}]) do
      {:ok, {{_version, _status, _reasonPhrase}, _headers, body}} -> case Floki.find(body, "a.social-count.js-social-count") |> Floki.attribute("aria-label") do
                                                                       [numAsText | _tail] -> get_number_from_text(numAsText)
                                                                       _-> numAsText1 = Floki.find(body, "a.social-count.js-social-count") |> Floki.text
                                                                           get_number_from_text(numAsText1)
                                                                     end
                                                                _ -> -555
            end

    %StarsTime{href: rs.href, stars: stars}
  end

  defp get_number_from_text(text) do
    stars = case Regex.run(~r/(\d+)/, text) do
              [ _, stars] -> String.to_integer(stars)
              _ -> -444
            end
    stars
  end
  def get_time do
    url = 'https://github.com/rozap/exquery'
    {:ok, {{_version, 200, _reasonPhrase}, _headers, body}} = :httpc.request(:get, {url, []}, [], [])
    dates = Regex.scan(~r/(><time-ago datetime="\d{4}-\d{2}-\d{2}T)/, :erlang.list_to_binary(body))
    dates1 = for [el1, _el2] <- dates do
      [e1, _] = Regex.run(~r/(\d{4}-\d{2}-\d{2})/, el1)
      e1
    end
    Enum.max(dates1)
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

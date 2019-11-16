defmodule CrawlerWeb.PageView do
  use CrawlerWeb, :view

  def set_curr_topic(curr_topic) do
    :ets.insert(:ets_storage, {:curr_topic, curr_topic})
  end

  def get_curr_topic() do
    [tuple] = :ets.lookup(:ets_storage, :curr_topic)
    {_key, value} = tuple
    value
  end
end

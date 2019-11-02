defmodule Crawler do
  @moduledoc """
  Crawler keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  use GenServer

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: :myCrawler)
  end

  # Callbacks
  @impl true
  def init(stack) do
    IO.inspect "CRAWLER INITED"
    send(self(), :crawl)
    {:ok, stack}
  end

  @impl true
  def handle_info(:crawl, state) do
    IO.inspect "CRAWLER HAD CRAWLED"
    parserStructs = Parser.get_content()
    Enum.map(parserStructs, &Storage.create_data/1)
    Process.flag(:trap_exit, true)
    IO.puts "Start get stars"
    stream = Task.async_stream(parserStructs, Parser, :get_stars_floki, [], [max_concurrency: 10, ordered: false, timeout: 50000])
    stars = Enum.to_list(stream)
    stars1 = Utils.get_stars_time_ok_status(stars)
    Enum.map(stars1, &Storage.update_stars/1)
    IO.puts "Stars was gotten"
    # In 24 hours
    Process.send_after(self(), :crawl, 24 * 60 * 60 * 1000)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    IO.inspect "CRAWLER HAD CRAWLED _msg"
    {:noreply, state}
  end

end

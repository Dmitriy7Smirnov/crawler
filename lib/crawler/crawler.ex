defmodule Crawler do
  @moduledoc """
  Crawler keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger
  use GenServer

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: :myCrawler)
  end

  # Callbacks
  @impl true
  def init(stack) do
    Logger.info("CRAWLER INITED")
    send(self(), :crawl)
    {:ok, stack}
  end

  @impl true
  def handle_info(:crawl, state) do
    Logger.info("CRAWLER HAD CRAWLED")
    parserStructs = Parser.get_repos()
    Enum.map(parserStructs, &Storage.create_data/1)
    Process.flag(:trap_exit, true)
    Logger.info("Start get stars")
    Task.async_stream(parserStructs, Parser, :get_stars_time_struct, [], [max_concurrency: 10, ordered: false, timeout: 50000])
      |> Enum.to_list()
      |> Enum.filter(fn {task_status, _} -> task_status == :ok end)
      |> Enum.map(fn {:ok , get_stars_time_struct_function_result} -> get_stars_time_struct_function_result end)
      |> Enum.filter(fn {get_stars_time_struct_status, _} -> get_stars_time_struct_status == :ok end)
      |> Enum.map(fn {_, starsTimeStruct} -> starsTimeStruct end)
      |> Enum.map(&Storage.update_stars/1)
    Logger.info("Stars was gotten")
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

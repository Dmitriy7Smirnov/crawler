defmodule Storage do
  use GenServer
  @ets_table :ets_storage

# Start the server
def start_link(_opts) do
  GenServer.start_link(__MODULE__, :ok, name: :myGenServer)
end

  # Callbacks
  @impl true
  def init(stack) do
    create_table()
    {:ok, stack}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect "handle_info storage begin"
    IO.inspect msg
    IO.inspect "handle_info storage end"
    {:noreply, state}
  end

  def create_table do
    :ets.new(@ets_table, [:set, :public, :named_table])
  end

  def create_data(new_data) do
    :ets.insert_new(@ets_table, {new_data.href, new_data})
  end

  def get_repos(threshold) do
    threshold1  =  case threshold do
                     threshold when is_integer(threshold) and threshold > 0 -> threshold
                     _ -> 0
                   end
    ms =  [{{:"$1",:"$2",:"$3"},[{:>=,:"$2",threshold1}],[{{:"$1",:"$3"}}]}]
    :ets.select(@ets_table, ms)
  end

  def update_stars(%StarsTime{href: key, stars: stars, time: time}) do
    [{key, repoStruct}] = :ets.lookup(@ets_table, key)
    repoStruct1 = %Repo{repoStruct | stars: stars, time: time}
    :ets.insert(@ets_table, {key, stars, repoStruct1})
  end

end

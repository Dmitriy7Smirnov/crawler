defmodule Storage do
  import Ex2ms
  @compile {:parse_transform, :ms_transform}
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

  def get_data(threshold) do
    ms = case threshold do
           10 -> fun do { key, stars, repo } when stars >= 10 -> {key, repo} end
           50 -> fun do { key, stars, repo } when stars >= 50 -> {key, repo} end
           100 -> fun do { key, stars, repo } when stars >= 100 -> {key, repo} end
           500 -> fun do { key, stars, repo } when stars >= 500 -> {key, repo} end
           1000 -> fun do { key, stars, repo } when stars >= 1000 -> {key, repo} end
               _-> fun do { key, stars, repo } when stars >= 0 -> {key, repo} end
         end
    :ets.select(@ets_table, ms)
  end

  def update_stars(%StarsTime{href: key, stars: stars, time: time}) do
    [{key, repoStruct}] = :ets.lookup(@ets_table, key)
    repoStruct1 = %Repo{repoStruct | stars: stars, time: time}
    :ets.insert(@ets_table, {key, stars, repoStruct1})
  end

end

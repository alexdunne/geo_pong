defmodule GeoPong.GameInstances.GameInstanceProcess do
  use GenServer, restart: :transient

  require Logger

  alias GeoPong.GameInstances.GameInstance

  def start_link(%GameInstance{} = game_instance) do
    GenServer.start_link(__MODULE__, game_instance,
      name: {:via, Registry, {GeoPong.GameInstanceRegistry, game_instance.id}}
    )
  end

  @impl true
  def init(%GameInstance{} = game_instance) do
    {:ok, game_instance}
  end

  # Callbacks

  @impl true
  def handle_call(:fetch, _from, %GameInstance{} = state) do
    {:reply, state, state}
  end

  # Client API

  def fetch(pid) do
    pid
    |> GenServer.call(:fetch)
  end
end

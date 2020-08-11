defmodule GeoPong.GameInstanceDynamicSupervisor do
  use DynamicSupervisor

  alias GeoPong.GameInstances.{GameInstance, GameInstanceProcess}

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_game_instance_to_supervisor(%GameInstance{} = game_instance) do
    child_spec = %{
      id: GameInstanceProcess,
      start: {GameInstanceProcess, :start_link, [game_instance]},
      restart: :transient
    }

    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def all_game_instance_pids do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.reduce([], fn {_, instance_pid, _, _}, acc ->
      [instance_pid | acc]
    end)
  end
end

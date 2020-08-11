defmodule GeoPong.GameInstanceRegistry do
  def child_spec do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__,
      partitions: System.schedulers_online()
    )
  end

  def lookup_game_instance(instance_id) do
    case Registry.lookup(__MODULE__, instance_id) do
      [{instance_pid, _}] ->
        {:ok, instance_pid}

      [] ->
        {:error, :not_found}
    end
  end
end

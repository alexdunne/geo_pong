defmodule GeoPongWeb.GameInstanceController do
  use GeoPongWeb, :controller

  alias GeoPong.GameInstances
  alias GeoPong.GameInstances.{GameInstance}

  def index(conn, _params) do
    instances = GameInstances.all()

    conn
    |> json(instances)
  end

  def show(conn, %{"id" => instance_id}) do
    instance = GameInstances.fetch(instance_id)

    case instance do
      %GameInstance{} = instance ->
        conn
        |> json(instance)

      _ ->
        conn
        |> put_status(404)
        |> json(%{"error" => "Game instance not found"})
    end
  end
end

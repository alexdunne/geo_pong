defmodule GeoPongWeb.GameInstanceController do
  use GeoPongWeb, :controller

  alias GeoPong.GameInstances
  alias GeoPong.GameInstances.{GameInstance}

  def index(conn, _params) do
    instances = GameInstances.all()

    IO.inspect(instances)

    conn
    |> json(instances)
  end

  def create(conn, _params) do
    instance = GameInstances.create()

    conn
    |> json(instance)
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
        |> json(%{"error" => "Game not found"})
    end
  end

  def join(conn, %{"game_instance_id" => instance_id}) do
    GameInstances.join(instance_id)
    |> case do
      {:ok, instance, player} ->
        conn
        |> json(%{
          "secret" => instance.secret,
          "player" => player
        })

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{"error" => "Game not found"})

      {:error, :game_full} ->
        conn
        |> json(%{"error" => "This game is full"})

      {:error, _} ->
        conn
        |> json(%{
          "error" =>
            "Something went wrong whilst attempting to join the game. Please try again shortly"
        })
    end
  end
end

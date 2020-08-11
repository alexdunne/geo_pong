defmodule GeoPong.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      GeoPongWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: GeoPong.PubSub},

      # Start the game instance registry
      GeoPong.GameInstanceRegistry.child_spec(),

      # Start the game instances supervisor
      GeoPong.GameInstanceDynamicSupervisor,

      # Start the Endpoint (http/https)
      GeoPongWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GeoPong.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GeoPongWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

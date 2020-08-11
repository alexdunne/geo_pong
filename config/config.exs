# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :geo_pong, GeoPongWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fIaqE7PcVmuCEsUuWff2QdzQj5PlXJMH2+u1NRv6aZ5EZH0cxflHglnXE37r6+jL",
  render_errors: [view: GeoPongWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GeoPong.PubSub,
  live_view: [signing_salt: "MlpBAJWh"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

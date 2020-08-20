:rand.seed(:exrop, {1, 2, 3})
:inets.start()
:ssl.start()

total_games = 100_000
concurrency = 20

1..total_games
|> Task.async_stream(
  fn _ ->
    url = 'http://localhost:4000/api/instance'
    method = :post
    :httpc.request(method, {url, [], 'application/json', '{}'}, [], [])
  end,
  max_concurrency: concurrency
)
|> Stream.run()

defmodule GeoPongWeb.Auth.PlayerAuth do
  alias GeoPong.GameInstances.Player

  @token_salt "game_player_socket"
  # 10 minutes in seconds
  @token_max_age 600

  def create_token(conn, %Player{id: player_id}) do
    Phoenix.Token.sign(conn, get_token_salt(), player_id)
  end

  def verify_token(socket, token) do
    Phoenix.Token.verify(socket, get_token_salt(), token, max_age: get_token_max_age())
  end

  defp get_token_salt do
    @token_salt
  end

  defp get_token_max_age do
    @token_max_age
  end
end

defmodule GeoPongWeb.PageController do
  use GeoPongWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

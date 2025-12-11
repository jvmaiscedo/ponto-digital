defmodule PontodigitalWeb.PageController do
  use PontodigitalWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

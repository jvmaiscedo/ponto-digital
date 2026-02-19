defmodule PontodigitalWeb.AdminLive.InboxLive.Show do
  use PontodigitalWeb, :live_view

  alias Pontodigital.{Communication, Repo}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Visualizar Mensagem")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    id = params["id"]
    return_to = params["return_to"] || ~p"/admin/inbox"

    message =
      Communication.get_inbox_message!(id)
      |> Repo.preload(:employee)

    if is_nil(message.read_at) do
      Communication.mark_as_read(message)
    end

    {:noreply,
     socket
     |> assign(:message, message)
     |> assign(:return_to, return_to)}
  end
end

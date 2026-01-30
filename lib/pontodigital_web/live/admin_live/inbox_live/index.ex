defmodule PontodigitalWeb.AdminLive.InboxLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Communication
  alias PontodigitalWeb.AdminLive.InboxLive.InboxComponents

  @impl true
  def mount(_params, _session, socket) do
    messages = Communication.list_inbox_messages()

    {:ok,
     socket
     |> assign(:page_title, "Caixa de Entrada")
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("mark_as_read", %{"id" => id}, socket) do
    message = Communication.get_inbox_message!(id)

    case Communication.mark_as_read(message) do
      {:ok, updated_message} ->
        {:noreply,
         socket
         |> put_flash(:info, "Mensagem marcada como lida.")
         |> stream_insert(:messages, updated_message)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao atualizar mensagem.")}
    end
  end

  def format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end
end

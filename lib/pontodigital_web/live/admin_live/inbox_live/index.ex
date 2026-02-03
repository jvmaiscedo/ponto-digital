defmodule PontodigitalWeb.AdminLive.InboxLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Communication
  alias PontodigitalWeb.AdminLive.InboxLive.InboxComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
    |> assign( :page_title, "Caixa de Entrada")
  |> stream(:messages, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case Communication.list_inbox_messages(params) do
      {:ok, {messages, meta}} ->
        {:noreply,
         socket
         |> assign(:meta, meta)
         |> stream(:messages, messages, reset: true)}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/admin/inbox")}
    end
  end

  @impl true
  def handle_event("mark_as_read", %{"id" => id}, socket) do
    message = Communication.get_inbox_message!(id)

    case Communication.mark_as_read(message) do
      {:ok, updated_message} ->
        updated_message = Pontodigital.Repo.preload(updated_message, :employee)
        {:noreply,
         socket
         |> put_flash(:info, "Mensagem marcada como lida.")
         |> stream(:messages, updated_message)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao atualizar mensagem.")}
    end
  end

  @impl true
  def handle_event("update-filter", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/admin/inbox?#{params}")}
  end

  def format_date(date) do
    Calendar.strftime(date, "%d/%m/%Y")
  end
end

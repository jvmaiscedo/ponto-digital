defmodule PontodigitalWeb.EmployeeLive.Components.ReportErrorComponent do
  use PontodigitalWeb, :live_component

  alias Pontodigital.Communication

  @impl true
  def mount(socket) do
    {:ok,
     allow_upload(socket, :document, accept: ~w(.pdf), max_entries: 1, max_file_size: 5_000_000)}
  end

  @impl true
  def update(assigns, socket) do
    changeset = Communication.change_inbox_message(%Communication.InboxMessage{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"inbox_message" => params}, socket) do
    changeset =
      %Communication.InboxMessage{}
      |> Communication.change_inbox_message(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"inbox_message" => params}, socket) do
    uploaded_path = consume_upload(socket)

    final_params =
      params
      |> Map.put("employee_id", socket.assigns.employee_id)
      |> Map.put("attachment_path", uploaded_path)

    case Communication.create_inbox_message(final_params) do
      {:ok, _message} ->
        send(self(), {:report_created, "Solicitação enviada com sucesso!"})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp consume_upload(socket) do
    consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "#{Ecto.UUID.generate()}#{ext}"
      dest_path = Path.join("priv/static/uploads/documents", filename)

      File.mkdir_p!(Path.dirname(dest_path))
      File.cp!(path, dest_path)

      {:ok, "/uploads/documents/#{filename}"}
    end)
    |> List.first()
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp format_date_br(date_str) do
    case String.split(date_str, "-") do
      [year, month, day] -> "#{day}/#{month}/#{year}"
      _ -> date_str
    end
  end

  def error_to_string(:too_large), do: "Arquivo muito grande (Máx 5MB)"
  def error_to_string(:not_accepted), do: "Apenas arquivos PDF são aceitos"
  def error_to_string(_), do: "Erro no upload"
end

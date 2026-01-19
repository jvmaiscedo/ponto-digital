defmodule PontodigitalWeb.EmployeeLive.ClockIn do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("registrar_ponto", %{"type" => type_string}, socket) do
    type = String.to_existing_atom(type_string)

    case Timekeeping.register_clock_in(socket.assigns.employee.id, type) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Ponto registrado com sucesso!")}

      {:error, :invalid_sequence, msg} ->
        {:noreply, put_flash(socket, :error, msg)}

      {:error, :duplicate_entry} ->
        {:noreply, put_flash(socket, :error, "Registro duplicado.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao registrar.")}
    end
  end
end

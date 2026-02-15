defmodule PontodigitalWeb.EmployeeLive.ClockIn do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping

  @impl true
  def mount(_params, _session, socket) do
    employee = socket.assigns.employee

    allowed_types = Timekeeping.get_allowed_types(employee.id)

    {:ok, assign(socket, :allowed_types, allowed_types)}
  end

  @impl true
  def handle_event("registrar_ponto", %{"type" => type_string}, socket) do
    type_string
    |> cast_clock_type()
    |> register_clock_in(socket)
  end

  defp cast_clock_type("entrada"), do: :entrada
  defp cast_clock_type("ida_almoco"), do: :ida_almoco
  defp cast_clock_type("retorno_almoco"), do: :retorno_almoco
  defp cast_clock_type("saida"), do: :saida
  defp cast_clock_type(_), do: nil

  defp register_clock_in(nil, socket) do
    {:noreply, put_flash(socket, :error, "Tipo de ponto inválido!")}
  end

  defp register_clock_in(type, socket) do
    socket.assigns.employee.id
    |> Timekeeping.register_clock_in(type)
    |> handle_registration_result(socket)
  end

  defp handle_registration_result({:ok, _clock}, socket) do
    new_allowed = Timekeeping.get_allowed_types(socket.assigns.employee.id)

    socket =
      socket
      |> put_flash(:info, "Ponto registrado com sucesso!")
      |> assign(:allowed_types, new_allowed)

    {:noreply, socket}
  end

  defp handle_registration_result({:error, :invalid_sequence, msg}, socket) do
    {:noreply, put_flash(socket, :error, msg)}
  end

  defp handle_registration_result({:error, :duplicate_entry}, socket) do
    {:noreply, put_flash(socket, :error, "Registro duplicado.")}
  end

  defp handle_registration_result({:error, _}, socket) do
    {:noreply, put_flash(socket, :error, "Erro ao registrar.")}
  end
end

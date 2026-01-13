defmodule PontodigitalWeb.ClockInLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Timekeeping
  alias Pontodigital.Company

  # Importar Componentes
  import PontodigitalWeb.ClockInLive.ClockInComponents

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    employee = Company.get_employee_by_user!(user.id)

    clock_ins = Timekeeping.list_clock_ins_by_employee(employee)

    {:ok,
     socket
     |> assign(clock_ins: clock_ins, mode: :registrar)
     |> assign(employee: employee)}
  end

  @impl true
  def handle_event("registrar_ponto", %{"type" => type_string}, socket) do
    with {:ok, type} <- parse_type(type_string),
         employee_id <- socket.assigns.employee.id,
         {:ok, clock_in} <- Timekeeping.register_clock_in(employee_id, type) do
      {:noreply,
       socket
       |> update(:clock_ins, &[clock_in | &1])
       |> put_flash(:info, "Ponto registrado com sucesso: #{type_string}")}
    else
      {:error, :invalid_type} ->
        {:noreply, put_flash(socket, :error, "Tipo de registro inválido.")}

      {:error, :invalid_sequence, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, :duplicate_entry} ->
        {:noreply, put_flash(socket, :error, "Você já registrou este tipo de ponto hoje.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erro ao registrar ponto.")}
    end
  end

  @impl true
  def handle_event("trocar_modo", %{"modo" => novo_modo}, socket) do
    modo_atom =
      case novo_modo do
        "registrar" -> :registrar
        "historico" -> :historico
        _ -> :registrar
      end

    {:noreply, assign(socket, mode: modo_atom)}
  end

  defp parse_type(type) when type in ~w(entrada saida ida_almoco retorno_almoco) do
    {:ok, String.to_existing_atom(type)}
  end

  defp parse_type(_), do: {:error, :invalid_type}
end

defmodule PontodigitalWeb.ClockInLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Timekeeping
  alias Pontodigital.Timekeeping.ClockIn
  alias Pontodigital.Company
  alias Pontodigital.Company.Employee

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
  def handle_event("registrar_ponto", params, socket) do
    employee = socket.assigns.employee

    type = Map.get(params, "type")

    atom_type =
      case type do
        "entrada" -> :entrada
        "saida" -> :saida
        "ida_almoco" -> :ida_almoco
        "retorno_almoco" -> :retorno_almoco
        _ -> :erro
      end

    if atom_type == :erro do
      {:noreply, put_flash(socket, :error, "Tipo inválido")}
    else
      last_type = check_last_clock_in_type(employee)

      if valid_sequence?(last_type, atom_type) do
        case Timekeeping.create_clock_in(%{
               employee_id: employee.id,
               timestamp: DateTime.utc_now(),
               type: atom_type,
               origin: :web
             }) do
          {:ok, ponto} ->
            socket = update(socket, :clock_ins, fn points -> [ponto | points] end)
            {:noreply, put_flash(socket, :info, "Ponto registrado: #{type}")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Erro ao registrar ponto.")}
        end
      else
        mensagem_erro =
          case last_type do
            :new -> "Você deve realizar uma entrada primeiro."
            _ -> "Movimento inválido! O último registro foi: #{last_type}"
          end
        {:noreply, put_flash(socket, :error, mensagem_erro)}
      end
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


  defp valid_sequence?(:new, :entrada), do: true
  defp valid_sequence?(:entrada, :saida), do: true
  defp valid_sequence?(:entrada, :ida_almoco), do: true
  defp valid_sequence?(:ida_almoco, :retorno_almoco), do: true
  defp valid_sequence?(:retorno_almoco, :saida), do: true
  defp valid_sequence?(:saida, :entrada), do: true
  defp valid_sequence?(_last, _new), do: false

  defp check_last_clock_in_type(%Employee{} = employee) do
    case Timekeeping.get_last_clock_in_by_employee(employee) do
      %ClockIn{type: tipo} -> tipo
      nil -> :new
    end
  end

  defp format_timestamp(timestamp) do
    local_time =
      case DateTime.shift_zone(timestamp, "America/Sao_Paulo") do
        {:ok, datetime} -> datetime
        _ -> timestamp
      end

    Calendar.strftime(local_time, "%d/%m/%Y %H:%M:%S")
  end
end

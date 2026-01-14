defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Show do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping
  alias Pontodigital.Timekeeping.ClockInAdjustment
  alias Pontodigital.Company
  import PontodigitalWeb.AdminLive.EmployeeManagement.TimesheetComponents

  @timezone "America/Sao_Paulo"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(editing_clock_in: nil)
     |> assign(new_point_form: nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    data_atual = Date.utc_today()
    {:noreply, load_timesheet(socket, id, data_atual)}
  end

  @impl true
  def handle_event("alterar_ponto", %{"id" => id}, socket) do
    ponto = Timekeeping.get_clock_in!(id)
    changeset = Timekeeping.change_adjustment(%ClockInAdjustment{})
    IO.inspect(ponto)

    {:noreply,
     assign(socket,
       editing_clock_in: ponto,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("fechar_modal", _params, socket) do
    {:noreply, assign(socket, editing_clock_in: nil)}
  end

  @impl true
  def handle_event("salvar_edicao", %{"clock_in_adjustment" => params}, socket) do
    clock_in = socket.assigns.editing_clock_in
    admin_id = socket.assigns.current_scope.user.id

    case params["type"] do
      "invalidado" ->
        handle_invalidation(socket, clock_in, params, admin_id)

      type when type in ["entrada", "saida", "ida_almoco", "retorno_almoco"] ->
        handle_update(socket, clock_in, params, admin_id, type)

      _ ->
        {:noreply, put_flash(socket, :error, "Tipo inválido.")}
    end
  end

  @impl true
  def handle_event("mudar_periodo", %{"periodo" => periodo_str}, socket) do
    data = parse_periodo_seguro(periodo_str)
    employee_id = socket.assigns.employee_id

    {:noreply, load_timesheet(socket, employee_id, data)}
  end

  @impl true
  def handle_event("abrir_novo_ponto", _params, socket) do
    types = %{
      type: :string,
      timestamp: :string,
      justification: :string,
      observation: :string
    }

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(%{}, Map.keys(types))

    {:noreply, assign(socket, new_point_form: to_form(changeset, as: :new_point))}
  end

  @impl true
  def handle_event("fechar_modal_criacao", _params, socket) do
    {:noreply, assign(socket, new_point_form: nil)}
  end

  @impl true
  def handle_event("salvar_novo_ponto", %{"new_point" => params}, socket) do
    admin_id = socket.assigns.current_scope.user.id
    employee_id = socket.assigns.employee_id

    # 1. Valida e converte o horário local para UTC
    case parse_local_to_utc(params["timestamp"]) do
      nil ->
        {:noreply, put_flash(socket, :error, "Data e Hora são obrigatórias.")}

      utc_timestamp ->
        # 2. Prepara os atributos para o Contexto
        attrs = %{
          "type" => params["type"],
          "timestamp" => utc_timestamp,
          "justification" => params["justification"],
          "observation" => params["observation"],
          "origin" => :manual
        }

        case Timekeeping.admin_create_clock_in(employee_id, attrs, admin_id) do
          {:ok, _clock_in} ->
            {:noreply,
             reload_timesheet_and_close(socket, "Ponto criado manualmente com sucesso.")}

          {:error, _reason} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Erro ao criar ponto. Verifique a sequência ou duplicidade."
             )}

          {:error, _reason, message} ->
            {:noreply, put_flash(socket, :error, message)}
        end
    end
  end

  # Private functions

  defp handle_invalidation(socket, clock_in, params, admin_id) do
    case Timekeeping.invalidate_clock_in(
           clock_in,
           params["justification"],
           params["observation"],
           admin_id
         ) do
      {:ok, _} ->
        {:noreply, reload_timesheet_and_close(socket, "Registro invalidado.")}

      {:error, _op, changeset, _} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_update(socket, clock_in, params, admin_id, type) do
    with {:ok, utc_timestamp} <- parse_and_validate_timestamp(params["novo_horario"]),
         {:ok, justification} <- validate_justification(params["justification"]) do
      attrs = %{
        "timestamp" => utc_timestamp,
        "justification" => justification,
        "observation" => params["observation"],
        "type" => String.to_existing_atom(type)
      }

      case Timekeeping.admin_update_clock_in(clock_in, attrs, admin_id) do
        {:ok, _} ->
          {:noreply, reload_timesheet_and_close(socket, "Ponto corrigido.")}

        {:error, _op, changeset, _} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp parse_and_validate_timestamp(""), do: {:error, "Horário é obrigatório."}
  defp parse_and_validate_timestamp(nil), do: {:error, "Horário é obrigatório."}

  defp parse_and_validate_timestamp(datetime_string) do
    case parse_local_to_utc(datetime_string) do
      nil -> {:error, "Formato de horário inválido."}
      timestamp -> {:ok, timestamp}
    end
  end

  defp validate_justification(""), do: {:error, "Justificativa é obrigatória."}
  defp validate_justification(nil), do: {:error, "Justificativa é obrigatória."}
  defp validate_justification(just), do: {:ok, just}

  defp reload_timesheet_and_close(socket, message) do
    employee_id = socket.assigns.employee_id
    date = parse_periodo_seguro(socket.assigns.mes_selecionado)

    socket
    |> put_flash(:info, message)
    |> assign(editing_clock_in: nil)
    |> assign(new_point_form: nil)
    |> load_timesheet(employee_id, date)
  end

  defp load_timesheet(socket, employee_id, date) do
    mapa_pontos = Timekeeping.list_timesheet(employee_id, date.year, date.month, @timezone)
    dias_do_mes = build_month_range(date)
    employee = Company.get_employee!(employee_id)

    days_data = Enum.map(dias_do_mes, &prepare_day_data(&1, mapa_pontos, employee))

    total_minutos = Enum.reduce(days_data, 0, fn day, acc -> acc + day.saldo_minutos end)
    saldo_total_mes = format_time_balance(total_minutos)

    assign(socket,
      days_data: days_data,
      saldo_total_mes: saldo_total_mes,
      total_minutos_mes: total_minutos,
      employee_id: employee_id,
      employee: employee,
      employee_name: employee.full_name,
      mes_selecionado: format_month_input(date)
    )
  end

  defp prepare_day_data(day, mapa_pontos, employee) do
    pontos_dia = Map.get(mapa_pontos, day, %{})
    is_weekend = weekend?(day)

    {saldo_minutos, saldo_formatado} = calculate_balance(pontos_dia, employee, day)

    %{
      date: day,
      day_of_week: format_weekday(day),
      entrada: pontos_dia[:entrada],
      ida_almoco: pontos_dia[:ida_almoco],
      retorno_almoco: pontos_dia[:retorno_almoco],
      saida: pontos_dia[:saida],
      # Texto para exibir na tabela
      saldo: saldo_formatado,
      # Número para somar no total
      saldo_minutos: saldo_minutos,
      is_weekend: is_weekend,
      row_class: row_class(is_weekend),
      text_class: text_class(is_weekend)
    }
  end

  defp build_month_range(date) do
    primeiro_dia = Date.beginning_of_month(date)
    ultimo_dia = Date.end_of_month(date)
    Date.range(primeiro_dia, ultimo_dia)
  end

  defp parse_periodo_seguro(periodo_str) do
    case Date.from_iso8601("#{periodo_str}-01") do
      {:ok, data} -> data
      {:error, _} -> Date.utc_today()
    end
  end

  defp format_month_input(date) do
    Calendar.strftime(date, "%Y-%m")
  end

  defp weekend?(date) do
    Date.day_of_week(date) in [6, 7]
  end

  defp row_class(is_weekend) do
    if is_weekend do
      "bg-gray-50 dark:bg-zinc-800/50"
    else
      "hover:bg-gray-50 dark:hover:bg-zinc-700/50"
    end
  end

  defp text_class(is_weekend) do
    if is_weekend do
      "text-gray-400 dark:text-zinc-500"
    else
      "text-gray-900 dark:text-zinc-100"
    end
  end

  defp calculate_balance(pontos_dia, employee, date) do
    meta_minutos =
      if employee.work_schedule do
        employee.work_schedule.daily_hours * 60
      else
        480
      end

    with entrada when not is_nil(entrada) <- pontos_dia[:entrada],
         saida when not is_nil(saida) <- pontos_dia[:saida] do
      entrada_time = entrada.original.timestamp
      saida_time = saida.original.timestamp

      almoco_minutos = calculate_lunch_break(pontos_dia)

      diff_seconds = DateTime.diff(saida_time, entrada_time, :second)
      diff_minutos = div(diff_seconds, 60)

      trabalhados_minutos = diff_minutos - almoco_minutos

      saldo_minutos = trabalhados_minutos - meta_minutos

      {saldo_minutos, format_time_balance(saldo_minutos)}
    else
      _ ->
        is_working_day =
          if employee.work_schedule do
            Date.day_of_week(date) in employee.work_schedule.work_days
          else
            not weekend?(date)
          end

        is_hired = Date.compare(date, employee.admission_date) != :lt

        is_past_or_today = Date.compare(date, Date.utc_today()) != :gt

        if is_working_day and is_hired and is_past_or_today do
          debito = -meta_minutos
          {debito, format_time_balance(debito)}
        else
          {0, "--:--"}
        end
    end
  end

  defp calculate_lunch_break(pontos_dia) do
    with ida when not is_nil(ida) <- pontos_dia[:ida_almoco],
         retorno when not is_nil(retorno) <- pontos_dia[:retorno_almoco] do
      ida_time = ida.original.timestamp
      retorno_time = retorno.original.timestamp

      diff_seconds = DateTime.diff(retorno_time, ida_time, :second)
      div(diff_seconds, 60)
    else
      _ -> 0
    end
  end

  defp format_time_balance(minutos) do
    horas = div(abs(minutos), 60)
    mins = rem(abs(minutos), 60)
    sinal = if minutos < 0, do: "-", else: "+"

    "#{sinal}#{String.pad_leading(Integer.to_string(horas), 2, "0")}:#{String.pad_leading(Integer.to_string(mins), 2, "0")}"
  end

  defp format_weekday(date) do
    case Calendar.strftime(date, "%a") do
      "Mon" -> "Seg"
      "Tue" -> "Ter"
      "Wed" -> "Qua"
      "Thu" -> "Qui"
      "Fri" -> "Sex"
      "Sat" -> "Sáb"
      "Sun" -> "Dom"
      _ -> ""
    end
  end

  defp parse_local_to_utc(""), do: nil

  defp parse_local_to_utc(local_datetime_string) do
    # O input datetime-local muitas vezes vem sem segundos (ex: "2023-10-25T14:00")
    # O Elixir exige segundos.
    # Se a string for curta (16 chars), adicionamos ":00".
    clean_string =
      if String.length(local_datetime_string) == 16 do
        local_datetime_string <> ":00"
      else
        local_datetime_string
      end

    case NaiveDateTime.from_iso8601(clean_string) do
      {:ok, naive_dt} ->
        case DateTime.from_naive(naive_dt, @timezone) do
          {:ok, local_dt} ->
            DateTime.shift_zone!(local_dt, "Etc/UTC")

          {:error, _reason} ->
            nil
        end

      {:error, _} ->
        nil
    end
  end
end

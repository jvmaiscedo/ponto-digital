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
     |> assign(new_point_form: nil)
     |> assign(absence_form: nil)
     |> assign(absence_date: nil)}
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

    case parse_local_to_utc(params["timestamp"]) do
      nil ->
        {:noreply, put_flash(socket, :error, "Data e Hora são obrigatórias.")}

      utc_timestamp ->
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
            {:noreply, put_flash(socket, :error, "Erro ao criar ponto. Verifique a sequência.")}

          {:error, _reason, message} ->
            {:noreply, put_flash(socket, :error, message)}
        end
    end
  end

  @impl true
  def handle_event("abrir_abono", %{"date" => date_str}, socket) do
    # Changeset schemaless para o formulário
    types = %{date: :date, reason: :string, observation: :string}
    changeset = {%{}, types} |> Ecto.Changeset.cast(%{}, Map.keys(types))

    {:noreply,
     socket
     |> assign(absence_date: Date.from_iso8601!(date_str))
     |> assign(absence_form: to_form(changeset, as: :absence))}
  end

  @impl true
  def handle_event("fechar_modal_abono", _params, socket) do
    {:noreply, assign(socket, absence_form: nil, absence_date: nil)}
  end

  @impl true
  def handle_event("salvar_abono", %{"absence" => params}, socket) do
    admin_id = socket.assigns.current_scope.user.id
    employee_id = socket.assigns.employee_id

    attrs = %{
      # Usamos a data do assign por segurança
      "date" => socket.assigns.absence_date,
      "reason" => params["reason"],
      "observation" => params["observation"],
      "employee_id" => employee_id,
      "admin_user_id" => admin_id
    }

    case Timekeeping.create_absence(attrs) do
      {:ok, _absence} ->
        {:noreply, reload_timesheet_and_close_absence(socket, "Falta abonada com sucesso.")}

      {:error, changeset} ->
        {:noreply, assign(socket, absence_form: to_form(changeset, as: :absence))}
    end
  end

  @impl true
  def handle_event("remover_abono", %{"id" => id}, socket) do
    absence = Timekeeping.get_absence!(id)
    {:ok, _} = Timekeeping.delete_absence(absence)

    {:noreply, reload_timesheet_and_close_absence(socket, "Abono removido.")}
  end

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
    primeiro_dia = dias_do_mes.first
    ultimo_dia = dias_do_mes.last

    mapa_abonos = Timekeeping.list_absences_map(employee_id, primeiro_dia, ultimo_dia)
    employee = Company.get_employee!(employee_id)

    days_data = Enum.map(dias_do_mes, &prepare_day_data(&1, mapa_pontos, mapa_abonos, employee))

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

  defp prepare_day_data(day, mapa_pontos, mapa_abonos, employee) do
    pontos_dia = Map.get(mapa_pontos, day, %{})
    abono = Map.get(mapa_abonos, day)
    is_weekend = weekend?(day)

    {saldo_minutos, saldo_formatado} = calculate_balance(pontos_dia, employee, day, abono)

    %{
      date: day,
      day_of_week: format_weekday(day),
      entrada: pontos_dia[:entrada],
      ida_almoco: pontos_dia[:ida_almoco],
      retorno_almoco: pontos_dia[:retorno_almoco],
      saida: pontos_dia[:saida],
      abono: abono,
      saldo: saldo_formatado,
      saldo_minutos: saldo_minutos,
      is_weekend: is_weekend,
      row_class: row_class(is_weekend),
      text_class: text_class(is_weekend)
    }
  end

  defp calculate_balance(_points, _employee, _date, %Pontodigital.Timekeeping.Absence{}) do
    {0, "ABONADO"}
  end

  defp calculate_balance(points, employee, date, nil) do
    meta = get_daily_meta(employee)

    case calculate_worked_minutes(points) do
      {:ok, trabalhados} ->
        saldo = trabalhados - meta
        {saldo, format_time_balance(saldo)}

      :error ->
        check_penalty(employee, date, meta)
    end
  end

  defp get_daily_meta(%{work_schedule: %{daily_hours: hours}}), do: hours * 60
  defp get_daily_meta(_employee), do: 480

  defp calculate_worked_minutes(%{entrada: ent, saida: sai} = points)
       when not is_nil(ent) and not is_nil(sai) do
    entrada_time = ent.original.timestamp
    saida_time = sai.original.timestamp
    almoco = calculate_lunch_break(points)

    diff_seconds = DateTime.diff(saida_time, entrada_time, :second)
    {:ok, div(diff_seconds, 60) - almoco}
  end

  defp calculate_worked_minutes(_points), do: :error

  defp check_penalty(employee, date, meta) do
    if should_charge_absence?(employee, date) do
      debito = -meta
      {debito, format_time_balance(debito)}
    else
      {0, "--:--"}
    end
  end

  defp should_charge_absence?(employee, date) do
    working_day? = is_working_day?(employee, date)
    hired? = Date.compare(date, employee.admission_date) != :lt
    past_or_today? = Date.compare(date, Date.utc_today()) != :gt

    working_day? and hired? and past_or_today?
  end

  defp is_working_day?(%{work_schedule: %{work_days: days}}, date) do
    Date.day_of_week(date) in days
  end

  defp is_working_day?(_employee, date) do
    not weekend?(date)
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

  defp format_month_input(date), do: Calendar.strftime(date, "%Y-%m")
  defp weekend?(date), do: Date.day_of_week(date) in [6, 7]

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

  defp row_class(is_weekend) do
    if is_weekend,
      do: "bg-gray-50 dark:bg-zinc-800/50",
      else: "hover:bg-gray-50 dark:hover:bg-zinc-700/50"
  end

  defp text_class(is_weekend) do
    if is_weekend,
      do: "text-gray-400 dark:text-zinc-500",
      else: "text-gray-900 dark:text-zinc-100"
  end

  defp parse_local_to_utc(""), do: nil
  defp parse_local_to_utc(nil), do: nil

  defp parse_local_to_utc(local_datetime_string) do
    clean_string =
      if String.length(local_datetime_string) == 16 do
        local_datetime_string <> ":00"
      else
        local_datetime_string
      end

    case NaiveDateTime.from_iso8601(clean_string) do
      {:ok, naive_dt} ->
        case DateTime.from_naive(naive_dt, @timezone) do
          {:ok, local_dt} -> DateTime.shift_zone!(local_dt, "Etc/UTC")
          {:error, _} -> nil
        end

      {:error, _} ->
        nil
    end
  end

  defp reload_timesheet_and_close_absence(socket, message) do
    employee_id = socket.assigns.employee_id
    date = parse_periodo_seguro(socket.assigns.mes_selecionado)

    socket
    |> put_flash(:info, message)
    |> assign(absence_form: nil, absence_date: nil)
    |> load_timesheet(employee_id, date)
  end
end

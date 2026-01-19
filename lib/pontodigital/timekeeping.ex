defmodule Pontodigital.Timekeeping do
  @moduledoc """
  The Timekeeping context.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Repo
  alias Ecto.Multi
  alias Pontodigital.Timekeeping.ClockIn
  alias Pontodigital.Timekeeping.ClockInAdjustment
  alias Pontodigital.Company.Employee
  alias Pontodigital.Timekeeping.Absence
  alias Pontodigital.Timekeeping.Vacation
  alias Pontodigital.Timekeeping.Holiday
  alias Pontodigital.Timekeeping.Calculator
  alias Pontodigital.Timekeeping.DailyLog

  @doc """
  Returns the list of clock_ins.

  ## Examples

      iex> list_clock_ins()
      [%ClockIn{}, ...]

  """
  def list_clock_ins do
    Repo.all(ClockIn)
  end

  def list_clock_ins_by_employee(%Employee{} = employee) do
    ClockIn
    |> where(employee_id: ^employee.id)
    |> order_by(desc: :timestamp)
    |> Repo.all()
  end

  def get_monthly_clock_ins(employee_id, year, month) do
    start_date = Date.new!(year, month, 1)

    end_date = Date.end_of_month(start_date)

    list_clock_ins_by_employee(employee_id, start_date, end_date)
  end

  defp list_clock_ins_by_employee(employee_id, start_date, end_date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(start_date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(end_date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.employee_id == ^employee_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  def list_clock_ins_by_user_in_day(employee_id, date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.employee_id == ^employee_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  def get_last_clock_in_by_employee(%Employee{} = employee) do
    get_last_clock_in_by_employee_id(employee.id)
  end

  def get_last_clock_in_by_employee_id(employee_id) do
    ClockIn
    |> where(employee_id: ^employee_id)
    |> where([c], c.status == :valid)
    |> order_by(desc: :timestamp)
    |> limit(1)
    |> Repo.one()
  end

  def register_clock_in(employee_id, type) do
    Repo.transaction(fn ->
      with {:ok, _} <- validate_no_duplicates(employee_id, type),
           last_clock <- get_last_clock_in_by_employee_id(employee_id),
           :ok <- validate_sequence(last_clock, type),
           attrs <- build_attrs(employee_id, type),
           {:ok, clock_in} <- create_clock_in(attrs) do
        clock_in
      else
        {:error, reason} when is_atom(reason) ->
          Repo.rollback(reason)

        {:error, reason, message} ->
          Repo.rollback({reason, message})

        {:error, %Ecto.Changeset{} = changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, clock_in} ->
        {:ok, clock_in}

      {:error, {reason, message}} when is_atom(reason) ->
        {:error, reason, message}

      {:error, reason} when is_atom(reason) ->
        {:error, reason}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  defp validate_no_duplicates(employee_id, type) do
    # Verificar se já existe registro deste tipo hoje
    today = Date.utc_today()

    query =
      from c in ClockIn,
        where: c.employee_id == ^employee_id,
        where: fragment("DATE(?)", c.timestamp) == ^today,
        where: c.type == ^type,
        where: c.status != :invalid

    case Repo.exists?(query) do
      false -> {:ok, :no_duplicates}
      true -> {:error, :duplicate_entry}
    end
  end

  defp build_attrs(employee_id, type) do
    %{
      employee_id: employee_id,
      timestamp: DateTime.utc_now(),
      type: type,
      origin: :web,
      status: :valid
    }
  end

  defp validate_sequence(nil, :entrada), do: :ok
  defp validate_sequence(%{type: :entrada}, type) when type in [:saida, :ida_almoco], do: :ok
  defp validate_sequence(%{type: :ida_almoco}, :retorno_almoco), do: :ok
  defp validate_sequence(%{type: :retorno_almoco}, :saida), do: :ok
  defp validate_sequence(%{type: :saida}, :entrada), do: :ok

  defp validate_sequence(%{type: last_type}, _new_type) do
    message = "Sequência inválida! Último registro: #{format_type(last_type)}"
    {:error, :invalid_sequence, message}
  end

  defp validate_sequence(nil, _type) do
    {:error, :invalid_sequence, "Você deve fazer uma entrada primeiro."}
  end

  defp format_type(:entrada), do: "Entrada"
  defp format_type(:saida), do: "Saída"
  defp format_type(:ida_almoco), do: "Ida para Almoço"
  defp format_type(:retorno_almoco), do: "Retorno do Almoço"

  def list_timesheet(employee_id, year, month, timezone \\ "America/Sao_Paulo") do
    start_date = Date.new!(year, month, 1)
    end_date = Date.end_of_month(start_date)

    from_utc =
      Timex.to_datetime(start_date, timezone)
      |> Timex.beginning_of_day()
      |> Timex.to_datetime("UTC")

    to_utc =
      Timex.to_datetime(end_date, timezone)
      |> Timex.end_of_day()
      |> Timex.to_datetime("UTC")

    query =
      from c in ClockIn,
        where: c.employee_id == ^employee_id,
        where: c.timestamp >= ^from_utc and c.timestamp <= ^to_utc,
        where: c.status == :valid,
        order_by: [asc: c.timestamp]

    Repo.all(query)
    |> organize_by_day(timezone)
  end

  defp organize_by_day(clock_ins, timezone) do
    clock_ins
    |> Enum.map(fn clock_in ->
      local_datetime = Timex.to_datetime(clock_in.timestamp, timezone)

      %{
        original: clock_in,
        type: clock_in.type,
        date: Timex.to_date(local_datetime),
        time: Timex.format!(local_datetime, "{h24}:{m}")
      }
    end)
    |> Enum.group_by(fn item -> item.date end)
    |> Map.new(fn {date, points_list} ->
      points_map = %{
        entrada: Enum.find(points_list, fn p -> p.type == :entrada end),
        ida_almoco: Enum.find(points_list, fn p -> p.type == :ida_almoco end),
        retorno_almoco: Enum.find(points_list, fn p -> p.type == :retorno_almoco end),
        saida: Enum.find(points_list, fn p -> p.type == :saida end)
      }

      {date, points_map}
    end)
  end

  @doc """
  Gets a single clock_in.
  Raises `Ecto.NoResultsError` if the Clock in does not exist.

  ## Examples

      iex> get_clock_in!(123)
      %ClockIn{}

      iex> get_clock_in!(456)
      ** (Ecto.NoResultsError)

  """
  def get_clock_in!(id), do: Repo.get!(ClockIn, id)

  @doc """
  Creates a clock_in.

  ## Examples

      iex> create_clock_in(%{field: value})
      {:ok, %ClockIn{}}

      iex> create_clock_in(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_clock_in(attrs) do
    %ClockIn{}
    |> ClockIn.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a clock_in.

  ## Examples

      iex> update_clock_in(clock_in, %{field: new_value})
      {:ok, %ClockIn{}}

      iex> update_clock_in(clock_in, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_clock_in(%ClockIn{} = clock_in, attrs) do
    clock_in
    |> ClockIn.changeset(attrs)
    |> Repo.update()
  end

  def admin_update_clock_in(%ClockIn{} = clock_in, attrs, admin_id) do
    adjustment_attrs = %{
      "clock_in_id" => clock_in.id,
      "admin_user_id" => admin_id,
      "previous_timestamp" => clock_in.timestamp,
      "previous_type" => clock_in.type,
      "justification" => attrs["justification"],
      "observation" => attrs["observation"]
    }

    clock_in_changeset = ClockIn.changeset(clock_in, Map.put(attrs, "is_edited", true))

    adjustment_changeset = ClockInAdjustment.changeset(%ClockInAdjustment{}, adjustment_attrs)

    Multi.new()
    |> Multi.update(:clock_in, clock_in_changeset)
    |> Multi.insert(:adjustment, adjustment_changeset)
    |> Repo.transaction()
  end

  @doc """
  Cria um registro de ponto manualmente (Admin) com justificativa.
  """
  def admin_create_clock_in(employee_id, attrs, admin_id) do
    clock_in_attrs = %{
      "employee_id" => employee_id,
      "timestamp" => attrs["timestamp"],
      "type" => attrs["type"],
      "origin" => attrs["origin"] || :manual,
      "status" => :valid,
      "is_edited" => true
    }

    Multi.new()
    |> Multi.insert(:clock_in, ClockIn.changeset(%ClockIn{}, clock_in_attrs))
    |> Multi.run(:adjustment, fn repo, %{clock_in: clock_in} ->
      adjustment_attrs = %{
        "clock_in_id" => clock_in.id,
        "admin_user_id" => admin_id,
        "justification" => attrs["justification"],
        "observation" => attrs["observation"],
        "previous_timestamp" => nil,
        "previous_type" => nil
      }

      %ClockInAdjustment{}
      |> ClockInAdjustment.changeset(adjustment_attrs)
      |> repo.insert()
    end)
    |> Repo.transaction()
  end

  def invalidate_clock_in(%ClockIn{} = clock_in, justification, observation, admin_id) do
    adjustment_attrs = %{
      "clock_in_id" => clock_in.id,
      "admin_user_id" => admin_id,
      "previous_timestamp" => clock_in.timestamp,
      "previous_type" => clock_in.type,
      "justification" => justification,
      "observation" => observation
    }

    Multi.new()
    |> Multi.update(:clock_in, ClockIn.changeset(clock_in, %{status: :invalid}))
    |> Multi.insert(
      :adjustment,
      ClockInAdjustment.changeset(%ClockInAdjustment{}, adjustment_attrs)
    )
    |> Repo.transaction()
  end

  def change_adjustment(%ClockInAdjustment{} = adjustment, attrs \\ %{}) do
    ClockInAdjustment.changeset(adjustment, attrs)
  end

  @doc """
  Deletes a clock_in.

  ## Examples

      iex> delete_clock_in(clock_in)
      {:ok, %ClockIn{}}

      iex> delete_clock_in(clock_in)
      {:error, %Ecto.Changeset{}}

  """
  def delete_clock_in(%ClockIn{} = clock_in) do
    Repo.delete(clock_in)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking clock_in changes.

  ## Examples

      iex> change_clock_in(clock_in)
      %Ecto.Changeset{data: %ClockIn{}}

  """
  def change_clock_in(%ClockIn{} = clock_in, attrs \\ %{}) do
    ClockIn.changeset(clock_in, attrs)
  end

  # Abono de faltas

  @doc """
  Cria um registro de abono de falta.
  """
  def create_absence(attrs) do
    %Absence{}
    |> Absence.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lista todos os abonos de um funcionario dentro de um periodo (mes).
  Retorna um map para acesso rapido: %{Date => Absence}
  """
  def list_absences_map(employee_id, start_date, end_date) do
    from(a in Absence,
      where: a.employee_id == ^employee_id,
      where: a.date >= ^start_date and a.date <= ^end_date
    )
    |> Repo.all()
    |> Map.new(fn absence -> {absence.date, absence} end)
  end

  @doc """
  Remove um abono (caso o admin erre)
  """
  def delete_absence(%Absence{} = absence) do
    Repo.delete(absence)
  end

  def get_absence!(id), do: Repo.get!(Absence, id)

  # Feriados
  @doc """
  Lista todos os feriados dentro de um periodo
  Retorna um map para acesso rapido
  """
  def list_holidays_map(start_date, end_date) do
    from(h in Holiday,
      where: h.date >= ^start_date and h.date <= ^end_date,
      select: {h.date, h.name}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Cria um feriado
  """
  def create_holiday(attrs) do
    %Holiday{}
    |> Holiday.changeset(attrs)
    |> Repo.insert()
  end

  def change_holiday(%Holiday{} = holiday, attrs \\ %{}) do
    Holiday.changeset(holiday, attrs)
  end

  def delete_holiday(%Holiday{} = holiday) do
    Repo.delete(holiday)
  end

  def list_all_holidays do
    Repo.all(from h in Holiday, order_by: [asc: h.date])
  end

  def get_holiday!(id), do: Repo.get!(Holiday, id)

  # Vacation
  def create_vacation(attrs) do
    %Vacation{}
    |> Vacation.changeset(attrs)
    |> Repo.insert()
  end

  def get_vacation!(id) do
    Vacation
    |> Repo.get!(id)
  end

  def list_vacations(employee_id) do
    Vacation
    |> where([v], v.employee_id == ^employee_id)
    |> order_by([v], desc: v.start_date)
    |> Repo.all()
  end

  def delete_vacation(%Vacation{} = vacation) do
    Repo.delete(vacation)
  end

  def list_vacations_map(employee_id, start_date, end_date) do
    query =
      from v in Vacation,
        where: v.employee_id == ^employee_id,
        where: v.start_date <= ^end_date and v.end_date >= ^start_date

    vacations = Repo.all(query)

    Enum.reduce(vacations, %{}, fn vacation, acc ->
      range = Date.range(vacation.start_date, vacation.end_date)

      relevant_range =
        Enum.filter(range, fn date ->
          Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
        end)

      Enum.reduce(relevant_range, acc, fn date, map_acc ->
        Map.put(map_acc, date, vacation)
      end)
    end)
  end

  # centralizacao de relatorio completo para o espelho de ponto.

  def get_monthly_report(employee, date) do
    month_range = build_month_range(date)

    processed_days =
      employee
      |> load_context_data(month_range)
      |> process_month_days(month_range, employee)

    total_minutes = calculate_total_balance(processed_days)

    %{
      days: processed_days,
      total_minutes: total_minutes,
      formatted_total: Calculator.format_balance(total_minutes)
    }
  end

  defp build_month_range(date) do
    Date.range(Date.beginning_of_month(date), Date.end_of_month(date))
  end

  defp load_context_data(employee, range) do
    %{
      points:
        list_timesheet(employee.id, range.first.year, range.first.month, "America/Sao_Paulo"),
      absences: list_absences_map(employee.id, range.first, range.last),
      holidays: list_holidays_map(range.first, range.last),
      vacations: list_vacations_map(employee.id, range.first, range.last),
      daily_logs: list_daily_logs_map(employee.id, range.first, range.last)
    }
  end

  defp process_month_days(context, range, employee) do
    daily_meta = get_daily_meta(employee)

    Enum.map(range, fn date ->
      points = Map.get(context.points, date, %{})
      absence = Map.get(context.absences, date)
      holiday = Map.get(context.holidays, date)
      vacation = Map.get(context.vacations, date)
      daily_log = Map.get(context.daily_logs, date)

      {balance_minutes, balance_visual} =
        calculate_day_balance(points, daily_meta, absence, holiday, vacation, employee, date)

      %{
        date: date,
        points: points,
        abono: absence,
        feriado: holiday,
        ferias: vacation,
        daily_log: daily_log,
        saldo_minutos: balance_minutes,
        saldo_visual: balance_visual,
        is_weekend: weekend?(date)
      }
    end)
  end

  defp get_daily_meta(%{work_schedule: nil}), do: 480
  defp get_daily_meta(%{work_schedule: ws}), do: ws.daily_hours * 60

  defp calculate_day_balance(points, meta, absence, holiday, vacation, employee, date) do
    result = Calculator.calculate_daily_balance(points, meta, absence, holiday, vacation)

    case result do
      {:missing_records, default_debit} ->
        resolve_missing_records(default_debit, employee, date, holiday, vacation)

      result_ok ->
        result_ok
    end
  end

  defp resolve_missing_records(debit, employee, date, holiday, vacation) do
    case should_charge_absence?(employee, date, holiday, vacation) do
      true ->
        {debit, Calculator.format_balance(debit)}

      false ->
        {0, "--:--"}
    end
  end

  defp should_charge_absence?(employee, date, holiday_name, vacation) do
    not_holiday = is_nil(holiday_name)
    not_vacation = is_nil(vacation)
    is_working_day = check_working_day(employee, date)
    is_hired = Date.compare(date, employee.admission_date) != :lt
    past_or_today = Date.compare(date, Date.utc_today()) != :gt

    not_holiday and not_vacation and is_working_day and is_hired and past_or_today
  end

  defp check_working_day(%{work_schedule: nil}, date), do: not weekend?(date)
  defp check_working_day(%{work_schedule: ws}, date), do: Date.day_of_week(date) in ws.work_days

  defp weekend?(date), do: Date.day_of_week(date) in [6, 7]

  defp calculate_total_balance(days) do
    Enum.reduce(days, 0, fn day, acc -> acc + day.saldo_minutos end)
  end

  # Daily logs
  @doc """
  Busca o log de atividades de um funcionário em uma data específica.
  Retorna nil se não existir.
  """
  def get_daily_log(employee_id, date) do
    Repo.get_by(DailyLog, employee_id: employee_id, date: date)
  end

  @doc """
  Cria ou Atualiza o log de atividades do dia.
  """
  def save_daily_log(attrs) do
    employee_id = attrs["employee_id"] || attrs[:employee_id]
    date = attrs["date"] || attrs[:date]

    case get_daily_log(employee_id, date) do
      nil ->
        %DailyLog{}
        |> DailyLog.changeset(attrs)
        |> Repo.insert()

      existing_log ->
        existing_log
        |> DailyLog.changeset(attrs)
        |> Repo.update()
    end
  end

  defp list_daily_logs_map(employee_id, start_date, end_date) do
    from(l in DailyLog,
      where: l.employee_id == ^employee_id,
      where: l.date >= ^start_date and l.date <= ^end_date
    )
    |> Repo.all()
    |> Map.new(fn log -> {log.date, log} end)
  end
end

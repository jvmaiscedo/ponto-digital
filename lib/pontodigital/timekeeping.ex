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
  alias Pontodigital.Timekeeping.Holiday

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

  def delete_holiday(%Holiday{} = holiday) do
    Repo.delete(holiday)
  end

  def list_all_holidays do
    Repo.all(from h in Holiday, order_by: [asc: h.date])
  end

  def get_holiday!(id), do: Repo.get!(Holiday, id)
end

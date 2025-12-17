defmodule Pontodigital.Timekeeping do
  @moduledoc """
  The Timekeeping context.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Repo

  alias Pontodigital.Timekeeping.ClockIn
  alias Pontodigital.Company.Employee

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

  def list_clock_ins_by_employee(user_id, start_date, end_date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(start_date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(end_date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.user_id == ^user_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  def list_clock_ins_by_user_in_day(user_id, date) do
    timezone = "America/Sao_Paulo"

    start_utc =
      DateTime.new!(date, ~T[00:00:00], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    end_utc =
      DateTime.new!(date, ~T[23:59:59], timezone)
      |> DateTime.shift_zone!("Etc/UTC")

    ClockIn
    |> where([c], c.user_id == ^user_id)
    |> where([c], c.timestamp >= ^start_utc and c.timestamp <= ^end_utc)
    |> order_by(asc: :timestamp)
    |> Repo.all()
  end

  def get_last_clock_in_by_employee(%Employee{} = employee) do
    ClockIn
    |> where(employee_id: ^employee.id)
    |> order_by(desc: :timestamp)
    |> limit(1)
    |> Repo.one()
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
end

defmodule Pontodigital.Company do
  @moduledoc """
  The Company context.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Repo
  alias Pontodigital.Company.Employee
  alias Ecto.Multi
  alias Pontodigital.Accounts
  alias Pontodigital.Company.WorkSchedule

  def register_employee_with_user(attrs) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _changes ->
      Accounts.register_user(attrs)
    end)
    |> Multi.run(:employee, fn _repo, %{user: user} ->
      attrs
      |> Map.put("user_id", user.id)
      |> create_employee()
    end)
    |> Repo.transaction()
  end

  @doc """
  Constrói a query base para listagem, incluindo Joins e Filtros.
  Não executa a query, apenas retorna o struct Ecto.Query.
  """
  def list_employees_query(params \\ %{}) do
    search_term = params["q"] || ""

    last_clock_query =
      from c in Pontodigital.Timekeeping.ClockIn,
        distinct: [asc: :employee_id],
        order_by: [asc: :employee_id, desc: :timestamp],
        select: %{employee_id: c.employee_id, type: c.type}

    base_query =
      from e in Employee,
        as: :employee,
        join: u in assoc(e, :user),
        as: :user,
        left_join: last_clock in subquery(last_clock_query),
        on: last_clock.employee_id == e.id,
        as: :last_clock,
        select: %{
          employee: e,
          user: u,
          last_clock_type: last_clock.type
        }

    if search_term != "" do
      term = "%#{search_term}%"

      from [employee: e, user: u] in base_query,
        where: ilike(e.full_name, ^term) or ilike(u.email, ^term)
    else
      base_query
    end
  end

  @doc """
  Executa a query paginada e processa o status em memória.
  Substitui a antiga list_employees_with_details.
  """
  def list_employees_paginated(params \\ %{}) do
    query = list_employees_query(params)

    case Flop.validate_and_run(query, params, for: Employee) do
      {:ok, {results, meta}} ->
        employees_with_status =
          Enum.map(results, fn %{employee: emp, user: user, last_clock_type: type} ->
            status = derive_status(type)

            emp
            |> Map.put(:user, user)
            |> Map.put(:status, status)
          end)

        {:ok, {employees_with_status, meta}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp derive_status(type) when type in [:entrada, :retorno_almoco], do: :ativo
  defp derive_status(:ida_almoco), do: :almoco
  defp derive_status(_), do: :inativo

  def change_employee_for_admin(employee, attrs \\ %{}) do
    Employee.admin_update_changeset(employee, attrs)
  end

  def update_employee_as_admin(employee, attrs) do
    employee
    |> Employee.admin_update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a single employee.

  Raises `Ecto.NoResultsError` if the Employee does not exist.

  ## Examples

      iex> get_employee!(123)
      %Employee{}

      iex> get_employee!(456)
      ** (Ecto.NoResultsError)

  """
  def get_employee!(id) do
    Employee
    |> Repo.get!(id)
    |> Repo.preload(:work_schedule)
  end

  def get_employee_by_user(user_id) do
    Repo.get_by(Employee, user_id: user_id)
  end

  def get_employee_by_user!(user_id) do
    Repo.get_by!(Employee, user_id: user_id)
  end

  def count_employees() do
    Repo.aggregate(Employee, :count, :id)
  end

  @doc """
  Creates a employee.

  ## Examples

      iex> create_employee(%{field: value})
      {:ok, %Employee{}}

      iex> create_employee(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_employee(attrs) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a employee.

  ## Examples

      iex> update_employee(employee, %{field: new_value})
      {:ok, %Employee{}}

      iex> update_employee(employee, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a employee.

  ## Examples

      iex> delete_employee(employee)
      {:ok, %Employee{}}

      iex> delete_employee(employee)
      {:error, %Ecto.Changeset{}}

  """
  def delete_employee(%Employee{} = employee) do
    Repo.delete(employee)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking employee changes.

  ## Examples

      iex> change_employee(employee)
      %Ecto.Changeset{data: %Employee{}}

  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  @doc """
  Retorna a lista de jornadas de trabalho para usar em selects.
  """
  def list_work_schedules do
    Repo.all(WorkSchedule)
  end

  def get_work_schedule!(id), do: Repo.get!(WorkSchedule, id)

  def create_work_schedule(attrs \\ %{}) do
    %WorkSchedule{}
    |> WorkSchedule.changeset(attrs)
    |> Repo.insert()
  end

  def update_work_schedule(%WorkSchedule{} = work_schedule, attrs) do
    work_schedule
    |> WorkSchedule.changeset(attrs)
    |> Repo.update()
  end

  def delete_work_schedule(%WorkSchedule{} = work_schedule) do
    Repo.delete(work_schedule)
  end

  def change_work_schedule(%WorkSchedule{} = work_schedule, attrs \\ %{}) do
    WorkSchedule.changeset(work_schedule, attrs)
  end
end

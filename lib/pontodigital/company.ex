defmodule Pontodigital.Company do
  @moduledoc """
  The Company context.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Company.Department
  alias Pontodigital.Repo
  alias Pontodigital.Company.Employee
  alias Ecto.Multi
  alias Pontodigital.Accounts
  alias Pontodigital.Company.WorkSchedule
  alias Pontodigital.Company.Department

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
    |> Multi.run(:set_manager, fn repo, %{employee: employee} ->
      set_manager_transaction(repo, employee, attrs)
    end)
    |> Repo.transaction()
  end

  defp set_manager_transaction(repo, employee, attrs) do
    should_set_manager = attrs["set_as_manager"] == "true" || attrs[:set_as_manager] == true

    if should_set_manager && employee.department_id do
      repo.get!(Department, employee.department_id)
      |> Ecto.Changeset.change(manager_id: employee.id)
      |> repo.update()
    else
      {:ok, nil}
    end
  end

  @doc """
  Constrói a query base para listagem, incluindo Joins e Filtros.
  Não executa a query, apenas retorna o struct Ecto.Query.
  """
 def list_employees_query(params \\ %{}) do
    search_term = params["q"] || ""

    department_id = if params["department_id"] in ["", nil], do: nil, else: params["department_id"]
    exclude_id = params["exclude_id"]

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

    query =
      if department_id do
        from [employee: e] in base_query, where: e.department_id == ^department_id
      else
        base_query
      end

    query =
      if exclude_id do
        from [employee: e] in query, where: e.id != ^exclude_id
      else
        query
      end

    if search_term != "" do
      term = "%#{search_term}%"

      from [employee: e, user: u] in query,
        where: ilike(e.full_name, ^term) or ilike(u.email, ^term)
    else
      query
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

def list_admin_employees do
    from(e in Employee,
      join: u in assoc(e, :user),
      where: u.role == :admin,
      preload: [:user]
    )
    |> Repo.all()
  end
  def change_employee_for_admin(employee, attrs \\ %{}) do
    Employee.admin_update_changeset(employee, attrs)
  end

  def update_employee_as_admin(employee, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, Employee.admin_update_changeset(employee, attrs))
    |> Ecto.Multi.run(:manager_logic, fn repo, %{employee: updated_employee} ->
      set_manager? = attrs["set_as_manager"] == "true" or attrs[:set_as_manager] == true

      department = repo.get!(Department, updated_employee.department_id)
      is_current_manager = department.manager_id == updated_employee.id

      cond do
        set_manager? and not is_current_manager ->
          promote_to_manager(repo, updated_employee, department)

        not set_manager? and is_current_manager ->
          demote_from_manager(repo, updated_employee, department)

        true ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{employee: employee}} -> {:ok, employee}
      {:error, :employee, changeset, _} -> {:error, changeset}
      {:error, :manager_logic, changeset, _} -> {:error, changeset}
    end
  end

  defp promote_to_manager(repo, employee, department) do
    with {:ok, _} <- repo.update(Ecto.Changeset.change(department, manager_id: employee.id)) do
      user = repo.preload(employee, :user).user
      if user.role == :employee do
        user |> Ecto.Changeset.change(role: :admin) |> repo.update()
      else
        {:ok, user}
      end
    end
  end

  defp demote_from_manager(repo, employee, department) do
    with {:ok, _} <- repo.update(Ecto.Changeset.change(department, manager_id: nil)) do
      user = repo.preload(employee, :user).user
      if user.role == :admin do
        user |> Ecto.Changeset.change(role: :employee) |> repo.update()
      else
        {:ok, user}
      end
    end
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

  @doc """
  Busca um funcionário garantindo que o usuário solicitante tenha permissão.
  - Master: Pode buscar qualquer ID.
  - Admin (Gerente): Só pode buscar IDs do mesmo departamento.
  """
def get_employee_secure!(id, current_employee) do
    current_employee = Repo.preload(current_employee, :user)

    base_query =
      Employee
      |> join(:inner, [e], u in assoc(e, :user))
      |> preload([:user, :department])

    case current_employee.user do
      %{role: :master} ->
        Repo.get!(base_query, id)

      %{role: :admin} ->
        base_query
        |> where([e], e.id == ^id)
        |> where([e], e.department_id == ^current_employee.department_id)
        |> Repo.one!()

      _ ->
        raise Ecto.NoResultsError, queryable: Employee
    end
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

@doc """
  Retorna um %Ecto.Changeset{} para rastrear alterações no departamento.
  """
  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end

  def create_department(attrs \\ %{}) do
  %Department{}
  |> Department.changeset(attrs)
  |> Repo.insert()
end

def set_department_manager(department_id, manager_id) do
  Repo.get!(Department, department_id)
  |> Ecto.Changeset.change(manager_id: manager_id)
  |> Repo.update()
end
  def create_department_with_manager(dept_attrs, manager_attrs) do
  Repo.transaction(fn ->
    dept = Repo.insert!(%Department{name: dept_attrs.name})

    manager_attrs = Map.put(manager_attrs, :department_id, dept.id)
    manager = create_employee(manager_attrs)

    dept
    |> Ecto.Changeset.change(manager_id: manager.id)
    |> Repo.update!()
  end)
end



  def list_departments do
    Department
    |> Repo.all()
    |> Repo.preload(:manager)
  end

  @doc """
  Retorna a lista de departamentos que o usuário atual pode selecionar num formulário.
  - Master: Todos os departamentos.
  - Admin (Gerente): Apenas o próprio departamento.
  """
  def list_departments_for_select(%Employee{} = current_employee) do
    current_employee = Repo.preload(current_employee, :user)

    if current_employee.user.role == :master do
      list_departments()
    else
      department = get_department!(current_employee.department_id)
      [department]
    end
  end

  def get_department!(id) do
    Repo.get!(Department, id)
  end

  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
  end

  def delete_department(%Department{} = department) do
    Repo.delete(department)
  end
end

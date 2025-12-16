defmodule Pontodigital.Company do
  @moduledoc """
  The Company context.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Repo
  alias Pontodigital.Company.Employee
  alias Ecto.Multi
  alias Pontodigital.Accounts
  alias Pontodigital.Timekeeping

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
  Returns the list of employees.

  ## Examples

      iex> list_employees()
      [%Employee{}, ...]

  """
  def list_employees do
    Repo.all(Employee)
  end

 def list_employees_with_details(search_term \\ "") do
    query =
      from e in Employee,
      join: u in assoc(e, :user),
      order_by: [asc: e.full_name]

    query =
      if search_term != "" do
        term = "%#{search_term}%"
        where(query, [e, u], ilike(e.full_name, ^term) or ilike(u.email, ^term))
      else
        query
      end

    user_preload_query = from u in Pontodigital.Accounts.User,
      select: [:id, :email, :role]

    query
    |> Repo.all()
    |> Repo.preload(user: user_preload_query)
    |> populate_status()
  end

  defp populate_status(employees) do
    Enum.map(employees, fn emp ->
      last_point = Timekeeping.get_last_clock_in_by_employee(emp)
      status = case last_point do
        %{type: :entrada} -> :ativo
        %{type: :retorno_almoco} -> :ativo
        %{type: :ida_almoco} -> :almoco
        _ -> :inativo
      end

      %{emp | status: status}
    end)
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
  def get_employee!(id), do: Repo.get!(Employee, id)

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
end

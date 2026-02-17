defmodule Pontodigital.Company do
  @moduledoc """
  Contexto responsável pela estrutura organizacional.

  Gerencia Funcionários (`Employee`), Departamentos e Jornadas de Trabalho.
  Possui lógica complexa de transações para garantir consistência entre Usuários de Autenticação e Perfis de Funcionário.
  """

  import Ecto.Query, warn: false
  alias Pontodigital.Company.Department
  alias Pontodigital.Repo
  alias Pontodigital.Company.Employee
  alias Ecto.Multi
  alias Pontodigital.Accounts
  alias Pontodigital.Company.WorkSchedule
  alias Pontodigital.Company.Department

  @doc """
  Registra um funcionário e seu usuário de acesso simultaneamente.

  ## Fluxo da Transação (`Ecto.Multi`)
  1. **User:** Cria o registro na tabela de autenticação (`Accounts`).
  2. **Employee:** Cria o perfil profissional vinculado ao usuário criado.
  3. **Manager Link:** Se a flag `set_as_manager` estiver ativa, atualiza o Departamento correspondente para apontar este novo funcionário como gestor.

  ## Parâmetros
  - `attrs`: Mapa contendo os atributos mistos de usuário (email, senha) e funcionário (nome, cargo, etc).

  ## Retorno
  - `{:ok, %{user: %User{}, employee: %Employee{}}}`: Sucesso na transação completa.
  - `{:error, step, reason, changes}`: Falha em alguma etapa (user ou employee).
  """
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

  defp list_employees_query(params) do
    search_term = params["q"] || ""

    department_id =
      if params["department_id"] in ["", nil], do: nil, else: params["department_id"]

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

  @doc """
  Atualiza os dados de um funcionário por um administrador, gerenciando promoções e rebaixamentos de cargo.

  ## Lógica de Gestão (Side-Effects)
  Além de atualizar os campos do funcionário, esta função verifica a flag `set_as_manager`:
  - **Promoção:** Se `true`, define o funcionário como gestor do departamento e eleva seu `user.role` para `:admin`.
  - **Rebaixamento:** Se `false` (e ele era gestor), remove a gestão do departamento e rebaixa seu `user.role` para `:employee` (se ele não for admin por outro motivo).
  """
  def update_employee_as_admin(employee, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:employee, Employee.admin_update_changeset(employee, attrs))
    |> Ecto.Multi.run(:manager_logic, fn repo, %{employee: updated_employee} ->
      # Chamamos a nova função privada aqui, passando os attrs necessários
      manage_manager_role(repo, updated_employee, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{employee: employee}} -> {:ok, employee}
      {:error, :employee, changeset, _} -> {:error, changeset}
      {:error, :manager_logic, changeset, _} -> {:error, changeset}
    end
  end

  defp manage_manager_role(repo, employee, attrs) do
    set_manager? = attrs["set_as_manager"] == "true" or attrs[:set_as_manager] == true
    department = repo.get!(Department, employee.department_id)
    is_current_manager = department.manager_id == employee.id

    cond do
      set_manager? and not is_current_manager ->
        promote_to_manager(repo, employee, department)

      not set_manager? and is_current_manager ->
        demote_from_manager(repo, employee, department)

      true ->
        {:ok, nil}
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
  Busca um funcionário pelo ID.

  ## Parâmetros
  - `id`: Inteiro representando o ID do funcionário.

  ## Retorno
  - `%Employee{}`: Struct do funcionário com `:user`, `:work_schedule` e `:department` precarregados.
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrar.
  """
  def get_employee!(id) do
    Employee
    |> Repo.get!(id)
    |> Repo.preload(:work_schedule)
  end

  @doc """
  Busca um funcionário aplicando regras estritas de escopo de dados (Row-Level Security manual).

  ## Regras de Permissão
  - **Master:** Tem acesso irrestrito a qualquer ID.
  - **Admin (Gestor):** Só pode acessar funcionários que pertencem ao *mesmo departamento* que ele. Tentar acessar ID de outro departamento levanta `Ecto.NoResultsError`.
  - **Employee:** Não deve acessar esta função (o código levanta erro padrão para roles não tratadas).

  ## Exceções
  Levanta `Ecto.NoResultsError` se o registro não existir ou se o usuário não tiver permissão para vê-lo.
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

  @doc """
  Busca o perfil de funcionário associado a um `user_id` de autenticação.

  ## Parâmetros
  - `user_id`: ID da tabela `users`.

  ## Retorno
  - `%Employee{}`: Funcionário encontrado (com preloads).
  - `nil`: Se o usuário não tiver perfil de funcionário vinculado.
  """
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
  Cria um funcionário diretamente (sem criar usuário novo).
  Utilizado principalmente via `seeds.exs` ou quando o usuário já existe.

  ## Parâmetros
  - `attrs`: Mapa de atributos do funcionário.

  ## Retorno
  - `{:ok, %Employee{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def create_employee(attrs) do
    %Employee{}
    |> Employee.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atualiza os dados de um funcionário existente.

  ## Parâmetros
  - `employee`: Struct do funcionário a ser atualizado.
  - `attrs`: Novos atributos.

  ## Retorno
  - `{:ok, %Employee{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def update_employee(%Employee{} = employee, attrs) do
    employee
    |> Employee.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Remove um funcionário do sistema.

  ## Parâmetros
  - `employee`: Struct do funcionário a ser removido.

  ## Retorno
  - `{:ok, %Employee{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro (ex: restrição de chave estrangeira se houver pontos vinculados).
  """
  def delete_employee(%Employee{} = employee) do
    Repo.delete(employee)
  end

  @doc """
  Gera um changeset para formulários de funcionário.

  ## Retorno
  - `%Ecto.Changeset{}`
  """
  def change_employee(%Employee{} = employee, attrs \\ %{}) do
    Employee.changeset(employee, attrs)
  end

  @doc """
  Lista todas as jornadas de trabalho cadastradas.

  ## Retorno
  - `[%WorkSchedule{}]`
  """
  def list_work_schedules do
    Repo.all(WorkSchedule)
  end

  @doc """
  Busca uma jornada de trabalho pelo ID.

  ## Retorno
  - `%WorkSchedule{}`
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrar.
  """
  def get_work_schedule!(id), do: Repo.get!(WorkSchedule, id)

  @doc """
  Cria uma nova jornada de trabalho.

  ## Parâmetros
  - `attrs`: Atributos da jornada (nome, carga horária, dias de trabalho).

  ## Retorno
  - `{:ok, %WorkSchedule{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def create_work_schedule(attrs \\ %{}) do
    %WorkSchedule{}
    |> WorkSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atualiza uma jornada de trabalho existente.

  ## Parâmetros
  - `work_schedule`: Struct original.
  - `attrs`: Novos atributos.

  ## Retorno
  - `{:ok, %WorkSchedule{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def update_work_schedule(%WorkSchedule{} = work_schedule, attrs) do
    work_schedule
    |> WorkSchedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Remove uma jornada de trabalho.

  ## Retorno
  - `{:ok, %WorkSchedule{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro (ex: se houver funcionários vinculados).
  """
  def delete_work_schedule(%WorkSchedule{} = work_schedule) do
    Repo.delete(work_schedule)
  end

  @doc """
  Gera um changeset para formulários de jornada.

  ## Retorno
  - `%Ecto.Changeset{}`
  """
  def change_work_schedule(%WorkSchedule{} = work_schedule, attrs \\ %{}) do
    WorkSchedule.changeset(work_schedule, attrs)
  end

  @doc """
  Gera um changeset para formulários de departamento.

  ## Retorno
  - `%Ecto.Changeset{}`
  """
  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end

  @doc """
  Cria um novo departamento simples.

  ## Parâmetros
  - `attrs`: Atributos do departamento.

  ## Retorno
  - `{:ok, %Department{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Define um funcionário como gestor de um departamento.

  ## Parâmetros
  - `department_id`: ID do departamento.
  - `manager_id`: ID do funcionário que será o novo gestor.

  ## Retorno
  - `{:ok, %Department{}}`: Departamento atualizado.
  - `{:error, %Ecto.Changeset{}}`: Erro na atualização.
  """
  def set_department_manager(department_id, manager_id) do
    Repo.get!(Department, department_id)
    |> Ecto.Changeset.change(manager_id: manager_id)
    |> Repo.update()
  end

  @doc """
  Cria um departamento e, atomicamente, cria e vincula seu gestor.
  Executa uma transação para garantir que o departamento não seja criado sem o gestor (se os dados forem fornecidos juntos).

  ## Parâmetros
  - `dept_attrs`: Atributos do departamento (nome).
  - `manager_attrs`: Atributos do funcionário gestor.

  ## Retorno
  - `{:ok, %Department{}}`: Sucesso (retorna o departamento com o gestor vinculado).
  - `{:error, reason}`: Falha na transação.
  """
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

  @doc """
  Lista todos os departamentos.

  ## Retorno
  - `[%Department{}]`: Lista com o gestor (`:manager`) precarregado.
  """
  def list_departments do
    Department
    |> Repo.all()
    |> Repo.preload(:manager)
  end

  @doc """
  Retorna a lista de departamentos que o usuário atual pode selecionar num formulário.

  ## Regra de Escopo
  - **Master:** Pode ver e selecionar todos os departamentos.
  - **Admin (Gestor):** Pode ver e selecionar apenas o seu próprio departamento.

  ## Parâmetros
  - `current_employee`: Struct do funcionário logado.

  ## Retorno
  - `[%Department{}]`: Lista filtrada de departamentos.
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

  @doc """
  Busca um departamento pelo ID.

  ## Retorno
  - `%Department{}`
  - **Lança Erro:** `Ecto.NoResultsError` se não encontrar.
  """
  def get_department!(id) do
    Repo.get!(Department, id)
  end

  @doc """
  Atualiza os dados de um departamento.

  ## Parâmetros
  - `department`: Struct original.
  - `attrs`: Novos atributos.

  ## Retorno
  - `{:ok, %Department{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro de validação.
  """
  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Remove um departamento.

  ## Retorno
  - `{:ok, %Department{}}`: Sucesso.
  - `{:error, %Ecto.Changeset{}}`: Erro (ex: se houver funcionários vinculados).
  """
  def delete_department(%Department{} = department) do
    Repo.delete(department)
  end
end

defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Accounts
  alias Pontodigital.Timekeeping

  import PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents

  @impl true
def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    current_employee =
      Company.get_employee_by_user(user_id)
      |> Pontodigital.Repo.preload([:department, :user])

    {:ok,
     socket
     |> assign(:current_employee, current_employee)
     |> stream(:employees, [])
     |> assign(search_term: "")
     |> assign(vacation_employee: nil)
     |> assign(vacation_form: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    params = if query == "", do: %{}, else: %{q: query}
    {:noreply, push_patch(socket, to: ~p"/admin/gestao-pessoas/funcionarios?#{params}")}
  end

  @impl true
  def handle_event("desativar_funcionario", %{"id" => id}, socket) do
    employee =
      Company.get_employee!(id)
      |> Pontodigital.Repo.preload(:user)

    case Accounts.update_user_status(employee.user, %{status: false}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Funcionário desativado com sucesso.")
         |> push_patch(to: ~p"/admin/gestao-pessoas/funcionarios")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao desativar funcionário.")}
    end
  end

  @impl true
  def handle_event("reativar_funcionario", %{"id" => id}, socket) do
    employee =
      Company.get_employee!(id)
      |> Pontodigital.Repo.preload(:user)

    case Accounts.update_user_status(employee.user, %{status: true}) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Funcionário reativado com sucesso.")
         |> push_patch(to: ~p"/admin/gestao-pessoas/funcionarios")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao reativar funcionário.")}
    end
  end

  @impl true
  def handle_event("abrir_modal_ferias", %{"id" => id}, socket) do
    employee = Company.get_employee!(id)

    types = %{start_date: :date, end_date: :date}
    changeset = {%{}, types} |> Ecto.Changeset.cast(%{}, Map.keys(types))

    {:noreply,
     socket
     |> assign(vacation_employee: employee)
     |> assign(vacation_form: to_form(changeset, as: :vacation))}
  end

  @impl true
  def handle_event("fechar_modal_ferias", _params, socket) do
    {:noreply, assign(socket, vacation_employee: nil, vacation_form: nil)}
  end

  @impl true
  def handle_event("salvar_ferias", %{"vacation" => params}, socket) do
    employee_id = socket.assigns.vacation_employee.id
    attrs = Map.put(params, "employee_id", employee_id)

    case Timekeeping.create_vacation(attrs) do
      {:ok, _vacation} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Férias registradas com sucesso para #{socket.assigns.vacation_employee.full_name}."
         )
         |> assign(vacation_employee: nil, vacation_form: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, vacation_form: to_form(changeset, as: :vacation))}
    end
  end

  defp apply_action(socket, :index, params) do
    flop_params = Map.put_new(params, "page_size", 10)

    current_employee = socket.assigns.current_employee
    is_master = current_employee.user.role == :master

    flop_params =
      if Map.has_key?(params, "q") and params["q"] != "" do
        Map.put(flop_params, "q", params["q"])
      else
        flop_params
      end

    flop_params =
      if is_master do
        if params["department_id"] && params["department_id"] != "" do
          Map.put(flop_params, "department_id", params["department_id"])
        else
          flop_params
        end
      else
        Map.put(flop_params, "department_id", current_employee.department_id)
      end

    flop_params = Map.put(flop_params, "exclude_id", current_employee.id)

    case Company.list_employees_paginated(flop_params) do
      {:ok, {employees, meta}} ->
        socket
        |> assign(:page_title, "Listagem de Funcionários")
        |> assign(:meta, meta)
        |> assign(:search_term, params["q"] || "")
        |> stream(:employees, employees, reset: true)

      {:error, _} ->
        put_flash(socket, :error, "Erro ao carregar lista.")
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    current_employee = socket.assigns.current_employee
    employee = Company.get_employee_secure!(id, current_employee)
    socket
    |> assign(:page_title, "Editar Funcionário")
    |> assign(:employee, employee)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Novo Funcionário")
    |> assign(:employee, %Company.Employee{})
  end
end

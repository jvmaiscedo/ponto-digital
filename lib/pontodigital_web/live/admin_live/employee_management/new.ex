defmodule PontodigitalWeb.AdminLive.EmployeeManagement.New do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Company.Employee

  import PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents

  @impl true
  def mount(_params, _session, socket) do
    current_employee = Company.get_employee_by_user!(socket.assigns.current_scope.user.id)
    changeset = Company.change_employee(%Employee{})
    work_schedules = Company.list_work_schedules()
    departments = Company.list_departments_for_select(current_employee)

    {:ok,
     socket
     |> assign(form: to_form(changeset))
     |> assign(work_schedules: work_schedules)
     |> assign(current_user: socket.assigns.current_scope.user)
     |> assign(departments: departments)}
  end

  # Validação
  @impl true
  def handle_event("validate", %{"employee" => employee_params}, socket) do
    changeset =
      %Employee{}
      |> Company.change_employee(employee_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"employee" => employee_params}, socket) do
    case Company.register_employee_with_user(employee_params) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Funcionário e Usuário criados com sucesso!")
         |> push_navigate(to: ~p"/admin/")}

      {:error, _failed_operation, changeset, _changes} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end

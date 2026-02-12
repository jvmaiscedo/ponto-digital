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
    current_employee = socket.assigns.current_employee |> Pontodigital.Repo.preload(:user)

    employee_params =
      if current_employee.user.role == :master do
        employee_params
      else
        employee_params
        |> Map.put("department_id", current_employee.department_id)
        |> Map.delete("set_as_manager")
      end

    case Company.create_employee(employee_params) do
      {:ok, _employee} ->
        {:noreply,
         socket
         |> put_flash(:info, "Funcionário criado com sucesso")
         |> push_navigate(to: ~p"/admin/gestao-pessoas/funcionarios")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end

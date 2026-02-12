defmodule PontodigitalWeb.AdminLive.EmployeeManagement.FormComponent do
  use PontodigitalWeb, :live_component

  alias Pontodigital.Company

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use este formulário para gerenciar os registros dos funcionários.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="employee-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:full_name]} type="text" label="Nome Completo" />

        <.input field={@form[:position]} type="text" label="Cargo / Posição" />

        <%
          is_single_department = length(@departments) == 1
          selected_department_id = if is_single_department, do: hd(@departments).id, else: nil
        %>

        <.input
          field={@form[:department_id]}
          type="select"
          label="Departamento"
          options={Enum.map(@departments, &{&1.name, &1.id})}
          prompt={if is_single_department, do: nil, else: "Selecione um departamento"}
          value={@form[:department_id].value || selected_department_id}
          disabled={is_single_department}
        />

        <%= if is_single_department do %>
          <input type="hidden" name="employee[department_id]" value={selected_department_id} />
        <% end %>

        <%= if @current_employee.user.role == :master do %>
          <.input
            field={@form[:set_as_manager]}
            type="checkbox"
            label="Definir como Gerente do Departamento"
          />
        <% end %>

        <.input
          field={@form[:work_schedule_id]}
          type="select"
          label="Jornada de Trabalho"
          options={Enum.map(@work_schedules, &{&1.name, &1.id})}
          prompt="Selecione a jornada"
        />

        <:actions>
          <.button phx-disable-with="Salvando...">Salvar Alterações</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

 @impl true
  def update(%{employee: employee} = assigns, socket) do
    is_manager =
      case employee.department do
        %{manager_id: manager_id} -> manager_id == employee.id
        _ -> false
      end
    changeset = Company.change_employee_for_admin(employee, %{set_as_manager: is_manager})
    departments = Company.list_departments_for_select(assigns.current_employee)
    work_schedules = Company.list_work_schedules()
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:departments, departments)
     |> assign(:work_schedules, work_schedules)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"employee" => employee_params}, socket) do
    changeset =
      socket.assigns.employee
      |> Company.change_employee_for_admin(employee_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
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

    save_employee(socket, socket.assigns.action, employee_params)
  end
 defp save_employee(socket, :edit, employee_params) do
    case Company.update_employee_as_admin(socket.assigns.employee, employee_params) do
      {:ok, employee} ->
        if employee_params["set_as_manager"] == "true" && employee.department_id do
          Company.set_department_manager(employee.department_id, employee.id)
        end

        notify_parent({:saved, employee})

        {:noreply,
         socket
         |> put_flash(:info, "Funcionário atualizado com sucesso")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end


  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

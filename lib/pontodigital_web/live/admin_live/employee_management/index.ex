defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Index do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Company
  alias Pontodigital.Accounts
  alias Pontodigital.Timekeeping

  import PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents

  @impl true
  def mount(_params, _session, socket) do
    employees = Company.list_employees_with_details("")

    {:ok,
     socket
     |> assign(employees: employees)
     |> assign(search_term: "")
     |> assign(vacation_employee: nil)
     |> assign(vacation_form: nil)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_employees = Company.list_employees_with_details(query)

    {:noreply,
     socket
     |> assign(employees: filtered_employees)
     |> assign(search_term: query)}
  end

  @impl true
  def handle_event("desativar_funcionario", %{"id" => id}, socket) do
    employee =
      Company.get_employee!(id)
      |> Pontodigital.Repo.preload(:user)

    case Accounts.update_user_status(employee.user, %{status: false}) do
      {:ok, _} ->
        employees = Company.list_employees_with_details("")

        {:noreply,
         socket
         |> put_flash(:info, "Funcionário desativado com sucesso.")
         |> assign(:employees, employees)}

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
        employees = Company.list_employees_with_details("")

        {:noreply,
         socket
         |> put_flash(:info, "Funcionário reativado com sucesso.")
         |> assign(:employees, employees)}

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
           "Ferias registradas com sucesso para #{socket.assigns.vacation_employee.full_name}."
         )
         |> assign(vacation_employee: nil, vacation_form: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, vacation_form: to_form(changeset, as: :vacation))}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Funcionário")
    |> assign(:employee, Company.get_employee!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listagem de Funcionários")
    |> assign(:employee, nil)
  end
end

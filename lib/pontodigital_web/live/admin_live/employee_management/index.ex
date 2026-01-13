defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Index do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Company
  alias Pontodigital.Accounts

  # Importa os componentes novos
  import PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents

  @impl true
  def mount(_params, _session, socket) do
    employees = Company.list_employees_with_details("")

    {:ok,
     socket
     |> assign(employees: employees)
     |> assign(search_term: "")}
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
        {:noreply, put_flash(socket, :info, "Funcionário desativado com sucesso.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao desativar funcionário.")}
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

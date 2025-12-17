defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Index do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Company

  @impl true
  @spec mount(any(), any(), any()) :: {:ok, any()}
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
  def handle_event("delete", %{"id" => id}, socket) do
    employee = Company.get_employee!(id)

    case Company.delete_employee(employee) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Funcionário excluído com sucesso.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao excluir funcionário.")}
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

  #funções auxiliares para modificar a cor do status
  defp status_class(status) when status in [:inativo, "inativo"] do
    "bg-red-50 text-red-700 ring-red-600/10 dark:bg-red-900/30 dark:text-red-400 dark:ring-red-400/20"
  end

  defp status_class(status) when status in [:almoco, "almoco"] do
    "bg-yellow-50 text-yellow-800 ring-yellow-600/20 dark:bg-yellow-900/30 dark:text-yellow-500 dark:ring-yellow-400/20"
  end

  defp status_class(_status) do
    "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-400/20"
  end
end

defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Index do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Company

  @impl true
  @spec mount(any(), any(), any()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    employees = Company.list_employees_with_details("")

    {:ok, socket
    |> assign(employees: employees)
    |>assign(search_term: "")}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_employees = Company.list_employees_with_details(query)

    {:noreply,
     socket
     |> assign(employees: filtered_employees)
     |> assign(search_term: query)}
  end


end

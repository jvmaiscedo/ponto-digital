defmodule PontodigitalWeb.AdminLive.DepartmentManagement.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Company.Department
  # Importa os componentes visuais que criamos
  import PontodigitalWeb.AdminLive.DepartmentManagement.DepartmentComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :departments, Company.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Departamento")
    |> assign(:department, Company.get_department!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Novo Departamento")
    |> assign(:department, %Department{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Departamentos")
    |> assign(:department, nil)
  end

  @impl true
  def handle_info({PontodigitalWeb.AdminLive.DepartmentManagement.FormComponent, {:saved, department}}, socket) do
    {:noreply, stream_insert(socket, :departments, department)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    department = Company.get_department!(id)
    {:ok, _} = Company.delete_department(department)

    {:noreply, stream_delete(socket, :departments, department)}
  end
end

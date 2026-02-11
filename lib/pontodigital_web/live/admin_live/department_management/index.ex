defmodule PontodigitalWeb.AdminLive.DepartmentManagement.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Company.Department

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
    |> assign(:page_title, "Listagem de Departamentos")
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

  # ATENÇÃO: O render deve estar no arquivo index.html.heex ou aqui embaixo.
  # Vou colocar aqui inline para facilitar a cópia.
  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-6 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-2xl font-semibold text-gray-900 dark:text-gray-100">Departamentos</h1>
          <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">
            Lista de todos os departamentos e seus respectivos gerentes.
          </p>
        </div>
        <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <.link patch={~p"/admin/configuracoes/departamentos/novo"}>
            <.button>Novo Departamento</.button>
          </.link>
        </div>
      </div>

      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <table class="min-w-full divide-y divide-gray-300 dark:divide-zinc-700">
              <thead>
                <tr>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 dark:text-gray-100 sm:pl-0">Nome</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 dark:text-gray-100">Gerente</th>
                  <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                    <span class="sr-only">Ações</span>
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-zinc-700" id="departments" phx-update="stream">
                <tr :for={{id, department} <- @streams.departments} id={id}>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 dark:text-gray-100 sm:pl-0">
                    <%= department.name %>
                  </td>
                  <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500 dark:text-gray-300">
                    <%= if department.manager, do: department.manager.full_name, else: "—" %>
                  </td>
                  <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                    <.link patch={~p"/admin/configuracoes/departamentos/#{department}/editar"} class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-900 mr-4">
                      Editar
                    </.link>
                    <.link
                      phx-click={JS.push("delete", value: %{id: department.id}) |> hide("##{id}")}
                      data-confirm="Tem certeza que deseja excluir este departamento?"
                      class="text-red-600 hover:text-red-900"
                    >
                      Excluir
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="department-modal"
        show
        on_cancel={JS.patch(~p"/admin/configuracoes/departamentos")}
      >
        <.live_component
          module={PontodigitalWeb.AdminLive.DepartmentManagement.FormComponent}
          id={@department.id || :new}
          title={@page_title}
          action={@live_action}
          department={@department}
          patch={~p"/admin/configuracoes/departamentos"}
        />
      </.modal>
    </div>
    """
  end
end

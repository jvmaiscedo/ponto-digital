defmodule PontodigitalWeb.AdminLive.DepartmentManagement.FormComponent do
  use PontodigitalWeb, :live_component

  alias Pontodigital.Company

 @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="px-4 sm:px-0 mb-6">
        <h2 class="text-lg font-semibold leading-7 text-zinc-900 dark:text-zinc-100">
          <%= @title %>
        </h2>
        <p class="mt-1 text-sm leading-6 text-zinc-500 dark:text-zinc-400">
          Preencha os dados abaixo para atualizar a estrutura organizacional.
        </p>
      </div>

      <.simple_form
        for={@form}
        id="department-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-4"
      >
        <.input
          field={@form[:name]}
          type="text"
          label="Nome do Departamento"
          placeholder="Ex: Recursos Humanos"
          required
        />

        <div class="mt-2">
          <.input
            field={@form[:manager_id]}
            type="select"
            label="Gerente Responsável"
            options={Enum.map(@employees, &{&1.full_name, &1.id})}
            prompt="Selecione um gestor (opcional)"
            class="block w-full rounded-md border-0 py-1.5 shadow-sm ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
          />
          <p class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
            Apenas funcionários com perfil administrativo aparecem aqui.
          </p>
        </div>

        <:actions>
          <.button phx-disable-with="Salvando..." class="w-full sm:w-auto">
            Salvar Alterações
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{department: department} = assigns, socket) do
    changeset = Company.change_department(department)
    employees = Company.list_admin_employees()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:employees, employees)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"department" => department_params}, socket) do
    changeset =
      socket.assigns.department
      |> Company.change_department(department_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"department" => department_params}, socket) do
    save_department(socket, socket.assigns.action, department_params)
  end

  defp save_department(socket, :edit, department_params) do
    case Company.update_department(socket.assigns.department, department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})

        {:noreply,
         socket
         |> put_flash(:info, "Departamento atualizado com sucesso")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_department(socket, :new, department_params) do
    case Company.create_department(department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})

        {:noreply,
         socket
         |> put_flash(:info, "Departamento criado com sucesso")
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

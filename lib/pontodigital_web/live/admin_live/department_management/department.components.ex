defmodule PontodigitalWeb.AdminLive.DepartmentManagement.DepartmentComponents do
  use PontodigitalWeb, :html

  @doc """
  Cabeçalho padrão para a gestão de departamentos.
  """
  def department_header(assigns) do
    ~H"""
    <header class="w-full flex items-center justify-between border-b border-zinc-200 dark:border-zinc-800 pb-6 mb-8">
    <div class="flex flex-col gap-1">
    <div class="flex-none w-full sm:w-auto flex justify-start">
        <.link
          navigate={~p"/admin/configuracoes"}
          class="group inline-flex items-center gap-2 text-sm font-medium text-zinc-500 hover:text-brand-600 dark:text-zinc-400 dark:hover:text-brand-400 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" />
          <span>Voltar</span>
        </.link>
      </div>
        <h1 class="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">
          <%= @title %>
        </h1>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">
          <%= @subtitle %>
        </p>
      </div>
      <div class="flex items-center gap-4">
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  @doc """
  Tabela estilizada para listagem de departamentos.
  """
  def department_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 shadow-sm">
      <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
        <thead class="bg-zinc-50 dark:bg-zinc-900/50">
          <tr>
            <th scope="col" class="px-6 py-4 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
              Departamento
            </th>
            <th scope="col" class="px-6 py-4 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
              Gestor Responsável
            </th>
            <th scope="col" class="relative px-6 py-4">
              <span class="sr-only">Ações</span>
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-200 dark:divide-zinc-700 bg-white dark:bg-zinc-800" id={@id} phx-update={@phx_update}>
          <tr :for={{id, department} <- @rows} id={id} class="group hover:bg-zinc-50 dark:hover:bg-zinc-900/50 transition-colors">
            <td class="whitespace-nowrap px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400">
                  <.icon name="hero-building-office-2" class="h-5 w-5" />
                </div>
                <div>
                  <div class="font-medium text-zinc-900 dark:text-zinc-100"><%= department.name %></div>
                  <div class="text-xs text-zinc-500">ID: <%= department.id %></div>
                </div>
              </div>
            </td>
            <td class="whitespace-nowrap px-6 py-4">
              <%= if department.manager do %>
                <div class="flex items-center gap-2">
                  <div class="h-8 w-8 rounded-full bg-zinc-200 dark:bg-zinc-700 flex items-center justify-center text-xs font-bold text-zinc-600 dark:text-zinc-300">
                    <%= String.at(department.manager.full_name, 0) %>
                  </div>
                  <div class="text-sm text-zinc-700 dark:text-zinc-300">
                    <%= department.manager.full_name %>
                  </div>
                </div>
              <% else %>
                <span class="inline-flex items-center rounded-md bg-zinc-100 dark:bg-zinc-800 px-2 py-1 text-xs font-medium text-zinc-500 ring-1 ring-inset ring-zinc-500/10">
                  Não definido
                </span>
              <% end %>
            </td>
            <td class="relative whitespace-nowrap px-6 py-4 text-right text-sm font-medium">
              <div class="flex justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                <.link
                  patch={~p"/admin/configuracoes/departamentos/#{department}/editar"}
                  class="text-zinc-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
                  title="Editar"
                >
                  <.icon name="hero-pencil-square" class="h-5 w-5" />
                </.link>
                <.link
                  phx-click={JS.push("delete", value: %{id: department.id}) |> hide("##{id}")}
                  data-confirm="Tem certeza que deseja remover este departamento?"
                  class="text-zinc-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
                  title="Excluir"
                >
                  <.icon name="hero-trash" class="h-5 w-5" />
                </.link>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end

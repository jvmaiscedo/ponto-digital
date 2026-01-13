defmodule PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents do
  @moduledoc """
  Componentes de UI para a listagem e gerenciamento de funcionários.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use PontodigitalWeb, :html

  @doc """
  Barra de busca e cabeçalho da listagem.
  """
  attr :search_term, :string, required: true

  def search_toolbar(assigns) do
    ~H"""
    <div class="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div class="flex-none">
        <.back_button navigate={~p"/admin/"} />
      </div>

      <div class="w-full sm:max-w-md">
        <form phx-change="search" onsubmit="return false;">
          <div class="relative">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <.icon name="hero-magnifying-glass" class="size-5 text-gray-400" />
            </div>
            <input
              type="text"
              name="query"
              value={@search_term}
              placeholder="Buscar por nome ou email..."
              class="block w-full rounded-md border-0 py-2 pl-10 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 shadow-sm"
              phx-debounce="300"
              autocomplete="off"
            />
          </div>
        </form>
      </div>
      <div>
        <PontodigitalWeb.Layouts.theme_toggle />
      </div>
    </div>
    """
  end

  @doc """
  Tabela de funcionários.
  """
  attr :employees, :list, required: true

  def employee_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm">
      <table class="min-w-full divide-y divide-gray-200 dark:divide-zinc-700">
        <thead class="bg-gray-50 dark:bg-zinc-900">
          <tr>
            <.table_header>Nome</.table_header>
            <.table_header>Cargo</.table_header>
            <.table_header>E-mail</.table_header>
            <.table_header>Status</.table_header>
            <.table_header class="text-center">Ações</.table_header>
          </tr>
        </thead>
        <tbody class="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700">
          <tr
            :for={employee <- @employees}
            class="hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors"
          >
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
              {employee.full_name}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-zinc-300">
              {employee.position}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-zinc-400">
              {employee.user.email}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm">
              <.status_badge status={employee.status} />
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
              <.action_buttons employee={employee} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Formulário completo de cadastro de funcionário.
  """
  attr :form, :map, required: true
  attr :work_schedules, :list, default: []

  attr :action, :string, default: "/admin/"

  def employee_registration_form(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl bg-white dark:bg-zinc-800 shadow-xl ring-1 ring-gray-900/5 dark:ring-white/10">
      <.form
        for={@form}
        phx-change="validate"
        phx-submit="save"
        class="divide-y divide-gray-200 dark:divide-zinc-700"
      >
        <div class="grid grid-cols-1 gap-x-8 gap-y-8 p-8 md:grid-cols-3">
          <div class="md:col-span-1">
            <h2 class="text-base font-semibold leading-7 text-gray-900 dark:text-white">
              Acesso ao Sistema
            </h2>
            <p class="mt-1 text-sm leading-6 text-gray-500 dark:text-zinc-400">
              Defina como este usuário fará login no Ponto Digital.
            </p>
          </div>

          <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-6 sm:grid-cols-6 md:col-span-2">
            <div class="sm:col-span-4">
              <.input
                field={@form[:email]}
                type="email"
                label="E-mail Corporativo"
                placeholder="nome@empresa.com"
                phx-debounce="500"
                class="block w-full rounded-md border-0 bg-transparent py-1.5 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-zinc-700 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                required
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:password]}
                type="password"
                label="Senha Inicial"
                placeholder="••••••••"
                phx-debounce="500"
                required
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:role]}
                type="select"
                label="Perfil de Acesso"
                options={[{"Funcionário", "employee"}, {"Administrador", "admin"}]}
                required
              />
            </div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-x-8 gap-y-8 p-8 md:grid-cols-3 bg-gray-50/50 dark:bg-zinc-800/50">
          <div class="md:col-span-1">
            <h2 class="text-base font-semibold leading-7 text-gray-900 dark:text-white">
              Dados Contratuais
            </h2>
            <p class="mt-1 text-sm leading-6 text-gray-500 dark:text-zinc-400">
              Informações para o espelho de ponto e relatórios.
            </p>
          </div>

          <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-6 sm:grid-cols-6 md:col-span-2">
            <div class="sm:col-span-6">
              <.input
                field={@form[:full_name]}
                type="text"
                label="Nome Completo"
                placeholder="Ex: João da Silva"
                phx-debounce="500"
                required
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:position]}
                type="text"
                label="Cargo"
                placeholder="Ex: Desenvolvedor"
                phx-debounce="500"
                required
              />
            </div>

            <div class="sm:col-span-3">
              <.input
                field={@form[:admission_date]}
                type="date"
                label="Data de Admissão"
                required
              />
            </div>

            <div class="sm:col-span-6">
              <div class="relative">
                <.input
                  field={@form[:work_schedule_id]}
                  type="select"
                  label="Jornada de Trabalho"
                  prompt="Selecione a jornada..."
                  options={Enum.map(@work_schedules, &{&1.name, &1.id})}
                  required
                />
                <p class="mt-1 text-xs text-gray-500 dark:text-zinc-500">
                  Isso definirá o cálculo de horas extras e atrasos.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-end gap-x-6 border-t border-gray-900/10 dark:border-white/10 px-4 py-4 sm:px-8 bg-gray-50 dark:bg-zinc-900/50">
          <.link
            navigate={@action}
            class="text-sm font-semibold leading-6 text-gray-900 dark:text-zinc-300 hover:text-zinc-100"
          >
            Cancelar
          </.link>
          <button
            type="submit"
            class="rounded-md bg-indigo-600 px-6 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-all"
          >
            Salvar Cadastro
          </button>
        </div>
      </.form>
    </div>
    """
  end

  # --- HELPERS (MANTIDOS) ---

  defp table_header(assigns) do
    ~H"""
    <th
      scope="col"
      class={[
        "px-6 py-4 text-xs font-medium text-gray-500 dark:text-zinc-400 uppercase tracking-wider",
        assigns[:class] || "text-left"
      ]}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :status, :any, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset",
      status_class(@status)
    ]}>
      {@status}
    </span>
    """
  end

  attr :employee, :map, required: true

  def action_buttons(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-4">
      <.link
        patch={~p"/admin/funcionarios/#{@employee.id}/editar"}
        class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
        aria-label="Editar"
      >
        <.icon name="hero-pencil-square" class="size-5" />
      </.link>

      <.link
        phx-click={JS.push("desativar_funcionario", value: %{id: @employee.id})}
        data-confirm="Tem certeza que deseja desativar este funcionário?"
        class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
        aria-label="Desativar"
      >
        <.icon name="hero-link" class="size-5" />
      </.link>

      <.link
        navigate={~p"/admin/funcionarios/#{@employee.id}"}
        class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
        aria-label="Ver Espelho"
      >
        <.icon name="hero-eye" class="size-5" />
      </.link>
    </div>
    """
  end

  defp status_class(status) when status in [:inativo, "inativo"] do
    "bg-red-50 text-red-700 ring-red-600/10 dark:bg-red-900/30 dark:text-red-400 dark:ring-red-400/20"
  end

  defp status_class(status) when status in [:almoco, "almoco"] do
    "bg-yellow-50 text-yellow-800 ring-yellow-600/10 dark:bg-yellow-900/30 dark:text-yellow-500 dark:ring-yellow-400/20"
  end

  defp status_class(_status) do
    "bg-green-50 text-green-700 ring-green-600/10 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-400/20"
  end
end

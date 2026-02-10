defmodule PontodigitalWeb.AdminLive.EmployeeManagement.EmployeeComponents do
  @moduledoc """
  Componentes de UI para a listagem e gerenciamento de funcionários.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use PontodigitalWeb, :html

  alias Flop.Phoenix, as: FlopUI

  @doc """
  Barra de busca e cabeçalho da listagem.
  """
  attr :search_term, :string, required: true

  def search_toolbar(assigns) do
    ~H"""
    <div class="mb-8 flex flex-col sm:flex-row items-center justify-between gap-4">
      <div class="flex-none w-full sm:w-auto flex justify-start">
        <.link
          navigate={~p"/admin/gestao-pessoas"}
          class="group inline-flex items-center gap-2 text-sm font-medium text-zinc-500 hover:text-brand-600 dark:text-zinc-400 dark:hover:text-brand-400 transition-colors"
        >
          <div class="flex size-8 items-center justify-center rounded-full bg-zinc-100 dark:bg-zinc-800 group-hover:bg-brand-50 dark:group-hover:bg-brand-900/20 transition-colors">
            <.icon name="hero-arrow-left" class="size-4" />
          </div>
          <span>Voltar</span>
        </.link>
      </div>

      <div class="w-full max-w-lg mx-auto">
        <form phx-change="search" onsubmit="return false;">
          <div class="relative group">
            <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
              <.icon
                name="hero-magnifying-glass"
                class="size-5 text-zinc-400 group-focus-within:text-brand-500 transition-colors"
              />
            </div>
            <input
              type="text"
              name="query"
              value={@search_term}
              class="block w-full rounded-full border-0 py-2.5 pl-11 pr-4 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6 dark:bg-zinc-800/50 dark:text-white dark:ring-zinc-700 dark:focus:ring-brand-500 transition-all"
              placeholder="Pesquisar funcionários..."
              phx-debounce="300"
              autocomplete="off"
            />
          </div>
        </form>
      </div>

      <div class="hidden sm:block flex-none w-auto sm:w-[88px]"></div>
    </div>
    """
  end

  @doc """
  Tabela de listagem de funcionários usando o componente da biblioteca Flop.
  """
  attr :employees, :list, required: true
  attr :meta, Flop.Meta, required: true

  def employee_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm flex flex-col">
      <FlopUI.table
        items={@employees}
        meta={@meta}
        path={~p"/admin/gestao-pessoas/funcionarios"}
        opts={[
          table_attrs: [class: "min-w-full divide-y divide-gray-200 dark:divide-zinc-700"],
          thead_attrs: [class: "bg-gray-50 dark:bg-zinc-900"],
          thead_th_attrs: [
            class:
              "px-6 py-4 text-xs font-medium uppercase tracking-wider text-left text-gray-500 dark:text-zinc-400"
          ],
          tbody_attrs: [
            class: "bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700",
            id: "employees-stream",
            "phx-update": "stream"
          ],
          tbody_tr_attrs: [class: "hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors"],
          tbody_td_attrs: [
            class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"
          ]
        ]}
      >
        <:col :let={{_id, employee}} label="Nome" field={:full_name}>
          <div class="flex items-center">
            <span class="font-medium text-gray-900 dark:text-white">
              {employee.full_name}
            </span>
          </div>
        </:col>

        <:col :let={{_id, employee}} label="Cargo" field={:position}>
          {employee.position}
        </:col>

        <:col :let={{_id, employee}} label="E-mail" field={:email}>
          {employee.user.email}
        </:col>

        <:col :let={{_id, employee}} label="Status" field={:status}>
          <.status_badge status={employee.status} />
        </:col>

        <:col
          :let={{_id, employee}}
          label="Ações"
          thead_th_attrs={[
            class:
              "px-6 py-4 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"
          ]}
        >
          <div class="flex justify-center">
            <.action_buttons employee={employee} />
          </div>
        </:col>
      </FlopUI.table>

      <div class="
        p-4 border-t border-gray-200 dark:border-zinc-700 bg-gray-50 dark:bg-zinc-900 flex justify-center
        [&_nav]:flex [&_nav]:justify-center
        [&_ul]:flex [&_ul]:flex-wrap [&_ul]:gap-1 [&_ul]:items-center
        [&_a]:px-3 [&_a]:py-1 [&_a]:rounded-md [&_a]:text-sm [&_a]:font-medium [&_a]:text-gray-600 dark:[&_a]:text-gray-400 [&_a]:transition-all
        [&_a:hover]:bg-white dark:[&_a:hover]:bg-zinc-800 [&_a:hover]:text-indigo-600 dark:[&_a:hover]:text-indigo-400 [&_a:hover]:shadow-sm [&_a:hover]:ring-1 [&_a:hover]:ring-gray-200 dark:[&_a:hover]:ring-zinc-700
        [&_span]:px-3 [&_span]:py-1 [&_span]:text-sm
        [&_span.current]:font-bold [&_span.current]:bg-indigo-600 [&_span.current]:text-white [&_span.current]:rounded-md [&_span.current]:shadow-sm
        [&_span.disabled]:text-gray-300 dark:[&_span.disabled]:text-zinc-600 [&_span.disabled]:cursor-not-allowed
      ">
        <FlopUI.pagination
          meta={@meta}
          path={~p"/admin/gestao-pessoas/funcionarios"}
        />
      </div>
    </div>
    """
  end

  # --- Helpers e Componentes Auxiliares ---

  attr :form, :map, required: true
  attr :work_schedules, :list, default: []
  attr :departments, :list, default: []
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
                field={@form[:department_id]}
                type="select"
                label="Departamento"
                prompt="Selecione um departamento"
                options={Enum.map(@departments, &{&1.name, &1.id})}
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

  attr :status, :atom, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset",
      status_class(@status)
    ]}>
      {status_label(@status)}
    </span>
    """
  end

  attr :employee, :map, required: true
  attr :form, :map, required: true

  def vacation_modal(assigns) do
    ~H"""
    <.modal
      id="vacation-modal"
      show
      on_cancel={JS.push("fechar_modal_ferias")}
    >
      <.header>
        Registrar Férias
        <:subtitle>
          Defina o período de férias para <span class="font-bold text-indigo-600 dark:text-indigo-400"><%= @employee.full_name %></span>.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vacation-form"
        phx-submit="salvar_ferias"
      >
        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:start_date]} type="date" label="Início" required />
          <.input field={@form[:end_date]} type="date" label="Fim" required />
        </div>

        <:actions>
          <.button phx-disable-with="Salvando..." class="w-full">
            Confirmar Férias
          </.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  attr :employee, :any, required: true

  defp action_buttons(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-4">
      <.link
        patch={~p"/admin/gestao-pessoas/funcionarios/#{@employee.id}/editar"}
        class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
        title="Editar"
      >
        <.icon name="hero-pencil-square" class="size-5" />
      </.link>

      <.link
        phx-click="abrir_modal_ferias"
        phx-value-id={@employee.id}
        class="text-gray-400 hover:text-teal-600 dark:hover:text-teal-400 transition-colors"
        aria-label="Registrar Férias"
        title="Registrar Férias"
      >
        <.icon name="hero-calendar" class="size-5" />
      </.link>

      <.link
        navigate={~p"/admin/gestao-pessoas/funcionarios/#{@employee.id}"}
        class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
        aria-label="Ver Espelho"
        title="Ver Espelho"
      >
        <.icon name="hero-eye" class="size-5" />
      </.link>

      <%= if @employee.user.status do %>
        <.link
          phx-click={JS.push("desativar_funcionario", value: %{id: @employee.id})}
          data-confirm="Tem certeza que deseja desativar este funcionário?"
          class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
          aria-label="Desativar Funcionario"
          title="Desativar Funcionario"
        >
          <.icon name="hero-link" class="size-5" />
        </.link>
      <% else %>
        <.link
          phx-click={JS.push("reativar_funcionario", value: %{id: @employee.id})}
          data-confirm="Tem certeza que deseja reativar este funcionário?"
          class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
          aria-label="Reativar Funcionario"
          title="Reativar Funcionario"
        >
          <.icon name="hero-arrow-uturn-left" class="size-5" />
        </.link>
      <% end %>
    </div>
    """
  end

  defp status_class(status) when status in [:inativo, "inativo"],
    do:
      "bg-red-50 text-red-700 ring-red-600/10 dark:bg-red-900/30 dark:text-red-400 dark:ring-red-400/20"

  defp status_class(status) when status in [:almoco, "almoco"],
    do:
      "bg-yellow-50 text-yellow-800 ring-yellow-600/20 dark:bg-yellow-900/30 dark:text-yellow-500 dark:ring-yellow-400/20"

  defp status_class(_),
    do:
      "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-400/20"

  defp status_label(status) when status in [:inativo, "inativo"], do: "Inativo"
  defp status_label(status) when status in [:almoco, "almoco"], do: "Em Almoço"
  defp status_label(_), do: "Ativo"
end

defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Menu do
  use PontodigitalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Gestão de Pessoas")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-8">
      <div class="mb-8">
        <.link
          navigate={~p"/admin"}
          class="inline-flex items-center gap-2 text-sm font-medium text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-200 transition-colors"
        >
          <.icon name="hero-arrow-left" class="size-4" />
          Voltar para Dashboard
        </.link>
        <h1 class="mt-4 text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">
          Gestão de Colaboradores
        </h1>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">
          Selecione uma operação abaixo.
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.link
          navigate={~p"/admin/gestao-pessoas/funcionarios"}
          class="group block p-6 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:border-blue-500 dark:hover:border-blue-500 transition-all shadow-sm hover:shadow-md"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400">
              <.icon name="hero-list-bullet" class="size-6" />
            </div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Listar Funcionários
            </h3>
          </div>
          <p class="text-zinc-500 dark:text-zinc-400 text-sm">
            Visualize a lista completa, busque por nome, edite dados contratuais e gerencie o status dos colaboradores.
          </p>
        </.link>

        <.link
          navigate={~p"/admin/gestao-pessoas/novo"}
          class="group block p-6 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:border-emerald-500 dark:hover:border-emerald-500 transition-all shadow-sm hover:shadow-md"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400">
              <.icon name="hero-user-plus" class="size-6" />
            </div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Registrar Novo
            </h3>
          </div>
          <p class="text-zinc-500 dark:text-zinc-400 text-sm">
            Adicione um novo colaborador ao sistema, definindo credenciais de acesso, departamento e jornada de trabalho.
          </p>
        </.link>
      </div>
    </div>
    """
  end
end

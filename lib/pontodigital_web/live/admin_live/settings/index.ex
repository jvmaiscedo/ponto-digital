defmodule PontodigitalWeb.AdminLive.Settings.Index do
  use PontodigitalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Configurações")}
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
          Parâmetros do Sistema
        </h1>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">
          Configurações globais de calendário, estrutura e turnos.
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <.link
          navigate={~p"/admin/configuracoes/feriados"}
          class="group block p-6 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:border-orange-500 dark:hover:border-orange-500 transition-all shadow-sm hover:shadow-md"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="p-3 rounded-lg bg-orange-50 dark:bg-orange-900/20 text-orange-600 dark:text-orange-400">
              <.icon name="hero-calendar-days" class="size-6" />
            </div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Calendário e Feriados
            </h3>
          </div>
          <p class="text-zinc-500 dark:text-zinc-400 text-sm">
            Cadastre feriados nacionais, estaduais e locais para garantir o cálculo correto de dias úteis e horas extras.
          </p>
        </.link>

        <.link
          navigate={~p"/admin/configuracoes/jornadas"}
          class="group block p-6 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:border-indigo-500 dark:hover:border-indigo-500 transition-all shadow-sm hover:shadow-md"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="p-3 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400">
              <.icon name="hero-clock" class="size-6" />
            </div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Jornadas de Trabalho
            </h3>
          </div>
          <p class="text-zinc-500 dark:text-zinc-400 text-sm">
            Defina os turnos, horários de entrada/saída e regras de tolerância para os diferentes tipos de contrato.
          </p>
        </.link>

        <.link
          navigate={~p"/admin/configuracoes/departamentos"}
          class="group block p-6 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:border-purple-500 dark:hover:border-purple-500 transition-all shadow-sm hover:shadow-md"
        >
          <div class="flex items-center gap-4 mb-4">
            <div class="p-3 rounded-lg bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400">
              <.icon name="hero-building-office-2" class="size-6" />
            </div>
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              Departamentos
            </h3>
          </div>
          <p class="text-zinc-500 dark:text-zinc-400 text-sm">
            Gerencie a estrutura organizacional, crie novos setores e defina os gerentes responsáveis por cada área.
          </p>
        </.link>
      </div>
    </div>
    """
  end
end

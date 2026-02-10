defmodule PontodigitalWeb.AdminLive.WorkScheduleManagement.WorkScheduleComponents do
  use PontodigitalWeb, :html
  alias Phoenix.LiveView.JS

  @doc """
  Barra de ferramentas superior com botão de voltar e ação principal.
  """
def toolbar(assigns) do
    ~H"""
    <div class="mb-8 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
      <div class="flex-none w-full sm:w-auto flex flex-col justify-start gap-4">
          <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-zinc-100">
            Jornadas de Trabalho
          </h1>
          <p class="text-sm text-gray-500 dark:text-zinc-400">
            Gerencie os turnos e escalas.
          </p>
        </div>


      <div class="flex items-center gap-2">
        <.link patch={~p"/admin/configuracoes/jornadas/nova"}>
          <button class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-all flex items-center gap-2">
            <.icon name="hero-plus" class="size-4" />
            Nova Jornada
          </button>
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Tabela de jornadas estilizada.
  """
  attr :work_schedules, :list, required: true

  def schedule_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm flex flex-col">
      <table class="min-w-full divide-y divide-gray-200 dark:divide-zinc-700">
        <thead class="bg-gray-50 dark:bg-zinc-900">
          <tr>
            <th scope="col" class="px-6 py-4 text-xs font-medium uppercase tracking-wider text-left text-gray-500 dark:text-zinc-400">
              Nome
            </th>
            <th scope="col" class="whitespace-nowrap px-6 py-4 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400">
              Carga Diária
            </th>
            <th scope="col" class="whitespace-nowrap px-6 py-4 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400">
              Horário
            </th>
            <th scope="col" class="whitespace-nowrap px-2 py-4 text-xs font-medium uppercase tracking-wider text-left text-gray-500 dark:text-zinc-400">
              Dias
            </th>
            <th scope="col" class="whitespace-nowrap px-6 py-4 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400">
              Ações
            </th>
          </tr>
        </thead>
        <tbody id="work_schedules" phx-update="stream" class="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700">
          <tr :for={{id, work_schedule} <- @work_schedules} id={id} class="hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors">
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white font-medium">
              <%= work_schedule.name %>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400 text-center">
              <%= work_schedule.daily_hours %>h
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400 text-center">
              <%= work_schedule.expected_start %> - <%= work_schedule.expected_end %>
            </td>

            <td class="px-2 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              <.work_days_badge days={work_schedule.work_days} />
            </td>

            <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
              <.action_buttons work_schedule={work_schedule} />
            </td>
          </tr>
        </tbody>
      </table>

      <%= if @work_schedules == [] do %>
        <div class="p-8 text-center text-gray-500 dark:text-zinc-400 text-sm">
          Nenhuma jornada cadastrada.
        </div>
      <% end %>
    </div>
    """
  end

  attr :work_schedule, :any, required: true

  defp action_buttons(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-4">
      <.link
        patch={~p"/admin/configuracoes/jornadas/#{@work_schedule.id}/editar"}
        class="text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
        title="Editar"
      >
        <.icon name="hero-pencil-square" class="size-5" />
      </.link>

      <.link
        phx-click={JS.push("delete", value: %{id: @work_schedule.id})}
        data-confirm="Tem certeza que deseja excluir esta jornada?"
        class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
        title="Excluir"
      >
        <.icon name="hero-trash" class="size-5" />
      </.link>
    </div>
    """
  end

  def work_days_badge(assigns) do
    ~H"""
    <div class="flex flex-nowrap gap-1">
      <%= if @days == [] or is_nil(@days) do %>
        <span class="text-xs text-gray-400">-</span>
      <% else %>
        <%= for day <- format_days_list(@days) do %>
          <span class="inline-flex items-center rounded bg-blue-50 px-1.5 py-0.5 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10 dark:bg-blue-400/10 dark:text-blue-400 dark:ring-blue-400/30">
            <%= day %>
          </span>
        <% end %>
      <% end %>
    </div>
    """
  end

  def format_days_list(days) do
    day_map = %{
      1 => "Seg", 2 => "Ter", 3 => "Qua", 4 => "Qui",
      5 => "Sex", 6 => "Sáb", 7 => "Dom"
    }
    days |> Enum.sort() |> Enum.map(&Map.get(day_map, &1))
  end

  def days_options do
    [
      {"Segunda-feira", 1}, {"Terça-feira", 2}, {"Quarta-feira", 3},
      {"Quinta-feira", 4}, {"Sexta-feira", 5}, {"Sábado", 6}, {"Domingo", 7}
    ]
  end
end

defmodule PontodigitalWeb.EmployeeLive.Components.ClockInComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  def clock_in_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <.action_button
        type="entrada"
        label="Entrada"
        icon="hero-arrow-right-end-on-rectangle"
        color="emerald"
      />
      <.action_button type="ida_almoco" label="Saída Almoço" icon="hero-pause" color="amber" />
      <.action_button type="retorno_almoco" label="Volta Almoço" icon="hero-play" color="blue" />
      <.action_button
        type="saida"
        label="Saída"
        icon="hero-arrow-left-start-on-rectangle"
        color="rose"
      />
    </div>
    """
  end

  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :color, :string, required: true

  def action_button(assigns) do
    ~H"""
    <button
      phx-click="registrar_ponto"
      phx-value-type={@type}
      class={"group relative flex flex-col items-center justify-center gap-3 rounded-xl border p-6 shadow-sm transition-all hover:shadow-md hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-offset-2 " <> color_classes(@color)}
    >
      <div class="p-3 rounded-full bg-white/20 shadow-inner">
        <.icon name={@icon} class="size-8" />
      </div>
      <span class="text-lg font-bold tracking-wide">{@label}</span>
    </button>
    """
  end

  attr :clock_ins, :list, required: true

  def history_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-zinc-900/5 dark:bg-zinc-900 dark:ring-white/10">
      <div class="border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50 px-6 py-4">
        <h3 class="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100">
          Registros Recentes
        </h3>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-800">
          <thead class="bg-zinc-50 dark:bg-zinc-800/50">
            <tr>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-zinc-500 dark:text-zinc-400"
              >
                Data e Hora
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-zinc-500 dark:text-zinc-400"
              >
                Tipo
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-zinc-500 dark:text-zinc-400"
              >
                Origem
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-200 bg-white dark:divide-zinc-800 dark:bg-zinc-900">
            <tr
              :for={point <- @clock_ins}
              class="group hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
            >
              <td class="whitespace-nowrap px-6 py-4 text-sm font-medium text-zinc-900 dark:text-zinc-100">
                <div class="flex items-center gap-2">
                  <.icon name="hero-calendar" class="size-4 text-zinc-400" />
                  {format_timestamp(point.timestamp)}
                </div>
              </td>
              <td class="whitespace-nowrap px-6 py-4 text-sm">
                {badge_type(point.type)}
              </td>
              <td class="whitespace-nowrap px-6 py-4 text-sm text-zinc-500 dark:text-zinc-400">
                <span class="inline-flex items-center rounded-md bg-zinc-100 px-2 py-1 text-xs font-medium text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400 ring-1 ring-inset ring-zinc-500/10">
                  {point.origin}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp color_classes("emerald"),
    do: "bg-emerald-600 text-white border-emerald-700 hover:bg-emerald-500 focus:ring-emerald-500"

  defp color_classes("amber"),
    do: "bg-amber-500 text-white border-amber-600 hover:bg-amber-400 focus:ring-amber-500"

  defp color_classes("blue"),
    do: "bg-blue-600 text-white border-blue-700 hover:bg-blue-500 focus:ring-blue-500"

  defp color_classes("rose"),
    do: "bg-rose-600 text-white border-rose-700 hover:bg-rose-500 focus:ring-rose-500"

  defp color_classes(_), do: "bg-zinc-600 text-white"

  defp badge_type(:entrada) do
    assigns = %{}

    ~H"""
    <span class="inline-flex items-center rounded-md bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
      Entrada
    </span>
    """
  end

  defp badge_type(:saida) do
    assigns = %{}

    ~H"""
    <span class="inline-flex items-center rounded-md bg-rose-50 px-2 py-1 text-xs font-medium text-rose-700 ring-1 ring-inset ring-rose-600/20">
      Saída
    </span>
    """
  end

  defp badge_type(_) do
    assigns = %{}

    ~H"""
    <span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
      Pausa
    </span>
    """
  end

  defp format_timestamp(timestamp) do
    local = DateTime.shift_zone!(timestamp, "America/Sao_Paulo")
    Calendar.strftime(local, "%d/%m/%Y às %H:%M")
  end
end

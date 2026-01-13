defmodule PontodigitalWeb.ClockInLive.ClockInComponents do
  @moduledoc """
  Componentes de UI para a área de registro de ponto do funcionário.
  """
  use Phoenix.Component
  use PontodigitalWeb, :html

  attr :mode, :atom, required: true

  def mode_selector(assigns) do
    ~H"""
    <div class="flex justify-center gap-4 mb-8">
      <.mode_button active={@mode == :registrar} label="Registrar Ponto" click="registrar" />
      <.mode_button active={@mode == :historico} label="Ver Histórico" click="historico" />
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :label, :string, required: true
  attr :click, :string, required: true

  defp mode_button(assigns) do
    ~H"""
    <button
      phx-click="trocar_modo"
      phx-value-modo={@click}
      class={"px-6 py-2 rounded-full font-bold transition-colors " <>
        if(@active,
          do: "bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900",
          else: "bg-gray-200 text-gray-600 hover:bg-gray-300 dark:bg-zinc-800 dark:text-zinc-400"
        )}
    >
      {@label}
    </button>
    """
  end

  def clock_in_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
      <.clock_in_button type="entrada" label="Entrada" sub="Iniciar jornada" color="green" />
      <.clock_in_button
        type="ida_almoco"
        label="Ida Almoço"
        sub="Pausa para refeição"
        color="orange"
      />
      <.clock_in_button
        type="retorno_almoco"
        label="Retorno Almoço"
        sub="Retomar jornada"
        color="blue"
      />
      <.clock_in_button type="saida" label="Saída" sub="Encerrar por hoje" color="red" />
    </div>
    """
  end

  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :sub, :string, required: true
  attr :color, :string, required: true

  def clock_in_button(assigns) do
    ~H"""
    <button
      phx-click="registrar_ponto"
      phx-value-type={@type}
      class={"flex flex-col items-center justify-center p-6 text-white rounded-xl shadow-lg transition-transform active:scale-95 #{color_class(@color)}"}
    >
      <span class="text-xl font-bold">{@label}</span>
      <span class="text-sm opacity-90">{@sub}</span>
    </button>
    """
  end

  attr :clock_ins, :list, required: true

  def history_table(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-800 shadow overflow-hidden rounded-lg border border-gray-300 dark:border-zinc-700">
      <div class="px-4 py-5 sm:px-6 bg-gray-100 dark:bg-zinc-900 border-b border-gray-300 dark:border-zinc-700">
        <h3 class="text-lg leading-6 font-medium text-zinc-900 dark:text-zinc-100">
          Histórico Recente
        </h3>
      </div>

      <table class="min-w-full divide-y divide-gray-300 dark:divide-zinc-700">
        <thead class="bg-gray-50 dark:bg-zinc-900">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-bold text-zinc-800 dark:text-zinc-200 uppercase">
              Data/Hora
            </th>
            <th class="px-6 py-3 text-left text-xs font-bold text-zinc-800 dark:text-zinc-200 uppercase">
              Tipo
            </th>
            <th class="px-6 py-3 text-left text-xs font-bold text-zinc-800 dark:text-zinc-200 uppercase">
              Origem
            </th>
          </tr>
        </thead>
        <tbody class="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700">
          <tr
            :for={point <- @clock_ins}
            class="hover:bg-gray-50 dark:hover:bg-zinc-700 transition-colors"
          >
            <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-900 dark:text-zinc-300">
              {format_timestamp(point.timestamp)}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-700 dark:text-zinc-300">
              {point.type}
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
              {point.origin}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # Função auxiliar para garantir que o Tailwind detecte as classes completas
  defp color_class("green"), do: "bg-green-600 hover:bg-green-700"
  defp color_class("orange"), do: "bg-orange-500 hover:bg-orange-600"
  defp color_class("blue"), do: "bg-blue-600 hover:bg-blue-700"
  defp color_class("red"), do: "bg-red-600 hover:bg-red-700"
  defp color_class(_), do: "bg-gray-600 hover:bg-gray-700"

  defp format_timestamp(timestamp) do
    local_time =
      case DateTime.shift_zone(timestamp, "America/Sao_Paulo") do
        {:ok, datetime} -> datetime
        _ -> timestamp
      end

    Calendar.strftime(local_time, "%d/%m/%Y %H:%M:%S")
  end
end

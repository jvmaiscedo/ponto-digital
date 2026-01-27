defmodule PontodigitalWeb.EmployeeLive.Components.HistoryComponents do
  @moduledoc """
  Componentes do espelho de ponto (Employee Side).
  Ajustado para replicar o layout do Admin (max-w-5xl e auto-width).
  """
  use Phoenix.Component
  use PontodigitalWeb, :html

  attr :month, :integer, required: true
  attr :year, :integer, required: true
  attr :employee, :map, required: true

  def filter_bar(assigns) do
    current_year = Date.utc_today().year
    admission_date_year = assigns.employee.admission_date.year
    years = admission_date_year..current_year

    months = [
      {1, "Janeiro"},
      {2, "Fevereiro"},
      {3, "Março"},
      {4, "Abril"},
      {5, "Maio"},
      {6, "Junho"},
      {7, "Julho"},
      {8, "Agosto"},
      {9, "Setembro"},
      {10, "Outubro"},
      {11, "Novembro"},
      {12, "Dezembro"}
    ]

    assigns = assign(assigns, months: months, years: years)

    ~H"""
    <div class="flex items-end gap-2">
      <.form for={%{}} phx-change="filter" class="flex items-center gap-2">
        <div class="w-32">
          <select
            name="month"
            class="block w-full rounded-md border-0 py-2 pl-3 pr-8 text-zinc-900 ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 cursor-pointer"
          >
            <%= for {val, name} <- @months do %>
              <option value={val} selected={val == @month}>{name}</option>
            <% end %>
          </select>
        </div>

        <div class="w-24">
          <select
            name="year"
            class="block w-full rounded-md border-0 py-2 pl-3 pr-8 text-zinc-900 ring-1 ring-inset ring-zinc-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 cursor-pointer"
          >
            <%= for y <- @years do %>
              <option value={y} selected={y == @year}>{y}</option>
            <% end %>
          </select>
        </div>
      </.form>

      <.link
        href={
          ~p"/workspace/relatorios/espelho?month=#{@month}&year=#{@year}&employee_id=#{@employee.id}"
        }
        class="hidden sm:inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 transition-colors"
      >
        <.icon name="hero-arrow-down-tray" class="size-4" /> Baixar PDF
      </.link>
    </div>
    """
  end

  attr :report, :map, required: true

  def report_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-zinc-200 dark:border-zinc-700 shadow-sm bg-white dark:bg-zinc-900">
      <div class="max-h-[80vh] overflow-y-auto relative">
        <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700 text-sm">
          <thead class="bg-zinc-50 dark:bg-zinc-900">
            <tr>
              <.table_header>Data</.table_header>
              <.table_header align="center">Entrada</.table_header>
              <.table_header align="center">Ida Almoço</.table_header>
              <.table_header align="center">Volta Almoço</.table_header>
              <.table_header align="center">Saída</.table_header>
              <.table_header align="right">Saldo</.table_header>
              <.table_header align="left">Obs / Diário</.table_header>
            </tr>
          </thead>

          <tbody class="divide-y divide-zinc-200 dark:divide-zinc-700 bg-white dark:bg-zinc-800">
            <%= for day <- @report.days do %>
              <.timesheet_row day={day} />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :day, :map, required: true

  defp timesheet_row(assigns) do
    row_class =
      if assigns.day.is_weekend,
        do: "bg-zinc-50/50 dark:bg-zinc-900/50",
        else: "hover:bg-zinc-50 dark:hover:bg-zinc-900/50 transition-colors"

    text_class =
      if assigns.day.is_weekend, do: "text-zinc-400", else: "text-zinc-900 dark:text-zinc-100"

    assigns = assign(assigns, row_class: row_class, text_class: text_class)

    ~H"""
    <tr class={@row_class}>
      <td class="px-4 py-2 whitespace-nowrap">
        <div class="flex flex-col">
          <span class={"font-medium " <> @text_class}>
            {Calendar.strftime(@day.date, "%d/%m")}
          </span>
          <span class="text-[10px] uppercase text-zinc-400">
            {day_week_name(@day.date)}
          </span>
        </div>
      </td>

      <.time_cell point={@day.points[:entrada]} type="entrada" faded={@day.is_weekend} />
      <.time_cell point={@day.points[:ida_almoco]} type="almoco" faded={@day.is_weekend} />
      <.time_cell point={@day.points[:retorno_almoco]} type="almoco" faded={@day.is_weekend} />
      <%= if is_nil(@day.points[:saida]) && inconsistent_day?(@day) do %>
        <td class="px-4 py-2 whitespace-nowrap text-center bg-amber-50/50 dark:bg-amber-900/10">
          <div class="tooltip tooltip-left" data-tip="Saída não registrada. Contate o admin.">
            <.icon name="hero-exclamation-triangle" class="size-5 text-amber-500 mx-auto cursor-help" />
          </div>
        </td>
      <% else %>
        <.time_cell point={@day.points[:saida]} type="saida" faded={@day.is_weekend} />
      <% end %>
      <td class="px-4 py-2 whitespace-nowrap text-right">
        <.balance_badge saldo={@day.saldo_visual} />
      </td>

      <td class="px-4 py-2 text-left align-middle">
        <div class="flex items-center gap-2">
          <%= if @day.daily_log do %>
            <div class="group relative inline-flex">
              <span class="cursor-help text-indigo-600 dark:text-indigo-400">
                <.icon name="hero-document-text" class="size-5" />
              </span>
              <div class="invisible group-hover:visible absolute right-full top-1/2 -translate-y-1/2 mr-2 w-64 p-3 bg-zinc-900 text-white text-xs rounded shadow-xl z-50">
                {@day.daily_log.description}
              </div>
            </div>
          <% end %>

          <%= cond do %>
            <% @day.ferias -> %>
              <.status_badge color="teal" icon="hero-sun" tooltip="Férias" />
            <% @day.feriado -> %>
              <.status_badge color="purple" icon="hero-sparkles" tooltip={"Feriado: #{@day.feriado}"} />
            <% @day.abono -> %>
              <.status_badge
                color="green"
                icon="hero-check-circle"
                tooltip={"Abonado: #{@day.abono.reason}"}
              />
            <% true -> %>
          <% end %>
        </div>
      </td>
    </tr>
    """
  end

  attr :class, :string, default: ""
  attr :align, :string, default: "left"
  slot :inner_block, required: true

  defp table_header(assigns) do
    ~H"""
    <th
      scope="col"
      class={[
        "sticky top-0 z-10 bg-zinc-50 dark:bg-zinc-900 px-4 py-3 font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider border-b border-zinc-200 dark:border-zinc-700",
        text_align_class(@align),
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :point, :map, default: nil
  attr :type, :string, required: true
  attr :faded, :boolean, default: false

  defp time_cell(assigns) do
    time_str =
      if assigns.point do
        assigns.point.original.timestamp
        |> DateTime.shift_zone!("America/Sao_Paulo")
        |> Calendar.strftime("%H:%M")
      else
        nil
      end

    assigns = assign(assigns, :time_str, time_str)

    ~H"""
    <td class="px-4 py-2 whitespace-nowrap text-center">
      <%= if @time_str do %>
        <span class={time_badge_class(@type, @faded)}>
          {@time_str}
        </span>
      <% else %>
        <span class="text-zinc-300 dark:text-zinc-700 text-xs">-</span>
      <% end %>
    </td>
    """
  end

  attr :saldo, :string, required: true
  attr :large, :boolean, default: false

  def balance_badge(assigns) do
    base = if assigns.large, do: "font-bold text-3xl", else: "font-mono text-xs font-semibold"

    color =
      cond do
        String.starts_with?(assigns.saldo, "+") -> "text-emerald-600 dark:text-emerald-400"
        String.starts_with?(assigns.saldo, "-") -> "text-rose-600 dark:text-rose-400"
        true -> "text-zinc-900 dark:text-zinc-100"
      end

    assigns = assign(assigns, class: "#{base} #{color}")

    ~H"""
    <span class={@class}>{@saldo}</span>
    """
  end

  attr :color, :string, required: true
  attr :icon, :string, required: true
  attr :tooltip, :string, required: true

  defp status_badge(assigns) do
    colors = %{
      "teal" =>
        "bg-teal-50 text-teal-700 ring-teal-600/20 dark:bg-teal-900/30 dark:text-teal-400",
      "purple" =>
        "bg-purple-50 text-purple-700 ring-purple-600/20 dark:bg-purple-900/30 dark:text-purple-400",
      "green" =>
        "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-900/30 dark:text-green-400"
    }

    assigns = assign(assigns, color_class: colors[assigns.color])

    ~H"""
    <span
      title={@tooltip}
      class={"inline-flex items-center justify-center rounded-full h-6 w-6 ring-1 ring-inset " <> @color_class}
    >
      <.icon name={@icon} class="size-4" />
    </span>
    """
  end

  defp text_align_class("left"), do: "text-left"
  defp text_align_class("center"), do: "text-center"
  defp text_align_class("right"), do: "text-right"

  defp time_badge_class(_type, true), do: "text-zinc-400 text-xs"

  defp time_badge_class("entrada", _),
    do:
      "inline-flex items-center rounded bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 ring-1 ring-inset ring-emerald-600/20 hover:bg-emerald-100 transition-colors cursor-default"

  defp time_badge_class("saida", _),
    do:
      "inline-flex items-center rounded bg-rose-50 px-2 py-1 text-xs font-medium text-rose-700 ring-1 ring-inset ring-rose-600/10 hover:bg-rose-100 transition-colors cursor-default"

  defp time_badge_class(_, _), do: "text-xs text-zinc-600 dark:text-zinc-300"

  defp day_week_name(date) do
    case Date.day_of_week(date) do
      1 -> "Seg"
      2 -> "Ter"
      3 -> "Qua"
      4 -> "Qui"
      5 -> "Sex"
      6 -> "Sáb"
      7 -> "Dom"
    end
  end

  defp inconsistent_day?(day) do
    today = Date.utc_today()
    is_past = Date.compare(day.date, today) == :lt

    has_activity = map_size(day.points) > 0

    missing_exit = is_nil(day.points[:saida])

    is_past and has_activity and missing_exit
  end
end

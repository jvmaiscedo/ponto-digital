defmodule PontodigitalWeb.AdminLive.EmployeeManagement.TimesheetComponents do
  @moduledoc """
  Componentes específicos para o espelho de ponto.
  """
  use Phoenix.Component
  import PontodigitalWeb.CoreComponents
  alias Phoenix.LiveView.JS

  @doc """
  Componente de filtro de período
  """
  attr :mes_selecionado, :string, required: true

  def period_filter(assigns) do
    ~H"""
    <div class="flex items-end gap-2">
      <.form for={%{}} phx-submit="mudar_periodo" class="flex items-center gap-2">
        <div class="relative">
          <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <.icon name="hero-calendar" class="size-5 text-gray-400" />
          </div>

          <input
            type="month"
            name="periodo"
            value={@mes_selecionado}
            required
            class="block w-full rounded-md border-0 py-2 pl-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 shadow-sm"
          />
        </div>

        <button
          type="submit"
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          Filtrar
        </button>
      </.form>
    </div>
    """
  end

  @doc """
  Tabela principal do espelho de ponto
  """
  attr :days_data, :list, required: true

  def timesheet_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm mt-8">
      <div class="max-h-[80vh] overflow-y-auto relative">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-zinc-700 text-sm">
          <thead class="bg-gray-50 dark:bg-zinc-900">
            <tr>
              <.table_header>Data</.table_header>
              <.table_header align="center">Entrada</.table_header>
              <.table_header align="center">Ida almoço</.table_header>
              <.table_header align="center">Retorno almoço</.table_header>
              <.table_header align="center">Saída</.table_header>
              <.table_header align="right">Saldo</.table_header>
              <.table_header align="right">Ações</.table_header>
            </tr>
          </thead>

          <tbody class="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700">
            <%= for day_data <- @days_data do %>
              <.timesheet_row day_data={day_data} />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :align, :string, default: "left"
  slot :inner_block, required: true

  defp table_header(assigns) do
    ~H"""
    <th
      scope="col"
      class={[
        "sticky top-0 z-10 bg-gray-50 dark:bg-zinc-900 px-4 py-3 font-medium text-gray-500 dark:text-zinc-400 uppercase tracking-wider border-b border-gray-200 dark:border-zinc-700",
        text_align_class(@align)
      ]}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :day_data, :map, required: true

  defp timesheet_row(assigns) do
    ~H"""
    <tr class={"transition-colors #{@day_data.row_class}"}>
      <!-- Data -->
      <td class="px-4 py-2 whitespace-nowrap">
        <div class="flex flex-col">
          <span class={"font-medium #{@day_data.text_class}"}>
            {Calendar.strftime(@day_data.date, "%d/%m")}
          </span>
          <span class="text-[10px] uppercase text-gray-400">
            {@day_data.day_of_week}
          </span>
        </div>
      </td>
      
    <!-- Entrada -->
      <.time_cell time_entry={@day_data.entrada} type="entrada" />
      
    <!-- Ida Almoço -->
      <.time_cell time_entry={@day_data.ida_almoco} type="almoco" />
      
    <!-- Retorno Almoço -->
      <.time_cell time_entry={@day_data.retorno_almoco} type="almoco" />
      
    <!-- Saída -->
      <.time_cell time_entry={@day_data.saida} type="saida" />
      
    <!-- Saldo -->
      <td class="px-4 py-2 whitespace-nowrap text-right">
        <.balance_badge saldo={@day_data.saldo} />
      </td>
      
    <!-- Ações -->
      <td class="px-4 py-2 whitespace-nowrap text-right">
        <div class="inline-flex">
          <!-- Placeholder para futuras ações -->
        </div>
      </td>
    </tr>
    """
  end

  attr :time_entry, :map, default: nil
  attr :type, :string, required: true

  defp time_cell(assigns) do
    ~H"""
    <td class="px-4 py-2 whitespace-nowrap text-center">
      <%= if @time_entry do %>
        <.link phx-click="alterar_ponto" phx-value-id={@time_entry.original.id}>
          <span class={time_badge_class(@type)}>
            {@time_entry.time}
          </span>
        </.link>
      <% else %>
        <span class="text-gray-300 text-xs">-</span>
      <% end %>
    </td>
    """
  end

  attr :saldo, :string, required: true

  defp balance_badge(assigns) do
    ~H"""
    <span class={balance_class(@saldo)}>
      {@saldo}
    </span>
    """
  end

  @doc """
  Modal de edição de ponto
  """
  attr :editing_clock_in, :map, required: true
  attr :form, :map, required: true

  def edit_modal(assigns) do
    ~H"""
    <.modal id="modal-editar-ponto" show on_cancel={JS.push("fechar_modal")}>
      <h2 class="text-lg font-bold text-gray-900 dark:text-zinc-100 mb-4">
        Corrigir Registro de Ponto
      </h2>

      <.simple_form for={@form} phx-submit="salvar_edicao">
        <div class="bg-gray-50 dark:bg-zinc-800 p-3 rounded-md mb-4 border border-gray-200 dark:border-zinc-700">
          <p class="text-sm text-gray-500 dark:text-zinc-400">Horário Original:</p>
          <p class="font-mono text-lg font-bold text-gray-900 dark:text-zinc-100">
            {@editing_clock_in.timestamp
            |> DateTime.shift_zone!("America/Sao_Paulo")
            |> Calendar.strftime("%d/%m/%Y - %H:%M")}
          </p>
          <p>Tipo:</p>
          <p class="font-mono text-lg font-bold text-gray-900 dark:text-zinc-100">
            {format_clock_in_type(@editing_clock_in.type)}
          </p>
        </div>

        <.input
          field={@form[:type]}
          type="select"
          label="Tipo"
          prompt="Selecione um tipo"
          options={[
            {"Entrada", :entrada},
            {"Saída", :saida},
            {"Ida para Almoço", :ida_almoco},
            {"Volta do Almoço", :retorno_almoco},
            {"Invalidar registro", :invalidado}
          ]}
          required
        />

        <.input
          field={@form[:timestamp]}
          type="datetime-local"
          label="Novo Horário"
        />

        <.input
          field={@form[:justification]}
          type="select"
          label="Justificativa"
          prompt="Selecione um motivo"
          options={[
            {"Esquecimento", :esquecimento},
            {"Problema Técnico", :problema_tecnico},
            {"Atestado Médico", :atestado_medico},
            {"Hora Extra", :hora_extra_autorizada},
            {"Outros", :outros}
          ]}
          required
        />

        <.input
          field={@form[:observation]}
          type="textarea"
          label="Observações (Detalhes)"
          placeholder="Ex: O relógio estava sem rede..."
        />

        <:actions>
          <.button class="w-full">Salvar Correção</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  defp text_align_class("left"), do: "text-left"
  defp text_align_class("center"), do: "text-center"
  defp text_align_class("right"), do: "text-right"
  defp text_align_class(_), do: "text-left"

  defp time_badge_class("entrada") do
    "cursor-pointer inline-flex items-center rounded bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20 hover:bg-green-100 hover:scale-105 transition-all"
  end

  defp time_badge_class("saida") do
    "cursor-pointer inline-flex items-center rounded bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 hover:bg-red-100 hover:scale-105 transition-all"
  end

  defp time_badge_class("almoco") do
    "cursor-pointer text-xs text-gray-600 dark:text-zinc-300 hover:text-indigo-600 hover:underline hover:font-bold transition-all"
  end

  defp time_badge_class(_), do: "text-xs text-gray-600 dark:text-zinc-300"

  defp balance_class("--:--") do
    "font-mono text-xs text-gray-400 dark:text-zinc-500"
  end

  defp balance_class(saldo) do
    base_class = "font-mono text-xs font-semibold"

    cond do
      String.starts_with?(saldo, "+") ->
        "#{base_class} text-green-600 dark:text-green-400"

      String.starts_with?(saldo, "-") ->
        "#{base_class} text-red-600 dark:text-red-400"

      true ->
        "#{base_class} text-gray-900 dark:text-zinc-100"
    end
  end

  defp format_clock_in_type(:entrada), do: "Entrada"
  defp format_clock_in_type(:saida), do: "Saída"
  defp format_clock_in_type(:ida_almoco), do: "Ida para Almoço"
  defp format_clock_in_type(:retorno_almoco), do: "Retorno do Almoço"
  defp format_clock_in_type(type), do: Phoenix.Naming.humanize(type)
end

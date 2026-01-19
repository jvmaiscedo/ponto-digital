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
    current_date =
      case Date.from_iso8601(assigns.mes_selecionado <> "-01") do
        {:ok, date} -> date
        _ -> Date.utc_today()
      end

    current_year = current_date.year
    years = (current_year - 5)..(current_year + 2)

    months = [
      {"Janeiro", "01"},
      {"Fevereiro", "02"},
      {"Março", "03"},
      {"Abril", "04"},
      {"Maio", "05"},
      {"Junho", "06"},
      {"Julho", "07"},
      {"Agosto", "08"},
      {"Setembro", "09"},
      {"Outubro", "10"},
      {"Novembro", "11"},
      {"Dezembro", "12"}
    ]

    assigns =
      assign(assigns,
        selected_month: Calendar.strftime(current_date, "%m"),
        selected_year: current_year,
        months: months,
        suggested_years: years
      )

    ~H"""
    <div class="flex items-end gap-2">
      <.form for={%{}} phx-submit="mudar_periodo" class="flex items-center gap-2">
        <div class="w-32">
          <select
            name="mes"
            class="block w-full rounded-md border-0 py-2 pl-3 pr-8 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700 cursor-pointer"
          >
            <%= for {name, value} <- @months do %>
              <option value={value} selected={value == @selected_month}>{name}</option>
            <% end %>
          </select>
        </div>

        <div class="w-24 relative">
          <input
            type="text"
            inputmode="numeric"
            pattern="[0-9]*"
            name="ano"
            value={@selected_year}
            list="years_list"
            placeholder="Ano"
            required
            class="block w-full rounded-md border-0 py-2 pl-3 pr-3 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:text-zinc-100 dark:ring-zinc-700"
          />
          <datalist id="years_list">
            <%= for year <- @suggested_years do %>
              <option value={year}></option>
            <% end %>
          </datalist>
        </div>

        <button
          type="submit"
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-colors"
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
              <.table_header align="center">Ações</.table_header>
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

      <.time_cell time_entry={@day_data.entrada} type="entrada" />
      <.time_cell time_entry={@day_data.ida_almoco} type="almoco" />
      <.time_cell time_entry={@day_data.retorno_almoco} type="almoco" />
      <.time_cell time_entry={@day_data.saida} type="saida" />

      <td class="px-4 py-2 whitespace-nowrap text-right">
        <.balance_badge saldo={@day_data.saldo} />
      </td>

      <td class="px-4 py-2 whitespace-nowrap">
        <div class="flex items-center justify-start gap-2">
          <%= cond do %>
            <% @day_data.ferias -> %>
              <button
                phx-click="remover_ferias"
                phx-value-id={@day_data.ferias.id}
                data-confirm="Tem certeza que deseja remover este período de férias?"
                class="group relative inline-flex h-8 w-8 items-center justify-center rounded-full bg-teal-50 text-teal-700 ring-1 ring-inset ring-teal-700/10 dark:bg-teal-900/30 dark:text-teal-400 dark:ring-teal-500/30 transition-all hover:scale-110 hover:bg-red-50 hover:text-red-600 hover:ring-red-600/20 dark:hover:bg-red-900/30 dark:hover:text-red-400"
                title="Em gozo de férias (Clique para remover)"
              >
                <.icon name="hero-sun" class="size-5 group-hover:hidden" />
                <.icon name="hero-trash" class="hidden size-4 group-hover:block" />
              </button>
            <% @day_data.feriado -> %>
              <span
                class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-purple-50 text-purple-700 ring-1 ring-inset ring-purple-700/10 dark:bg-purple-900/30 dark:text-purple-400 dark:ring-purple-500/30 cursor-help transition-transform hover:scale-105"
                title={"Feriado: #{@day_data.feriado}"}
              >
                <.icon name="hero-sparkles-solid" class="size-4" />
              </span>
            <% @day_data.abono -> %>
              <button
                phx-click="remover_abono"
                phx-value-id={@day_data.abono.id}
                data-confirm="Remover este abono?"
                class="group relative inline-flex h-8 w-8 items-center justify-center rounded-full bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-500/30 transition-all hover:scale-110 hover:bg-red-50 hover:text-red-600"
                title={"Abonado: #{@day_data.abono.reason}"}
              >
                <.icon name="hero-check-circle-solid" class="size-5 group-hover:hidden" />
                <.icon name="hero-trash" class="hidden size-4 group-hover:block" />
              </button>
            <% true -> %>
              <%= if @day_data.saldo_minutos < 0 do %>
                <button
                  phx-click="abrir_abono"
                  phx-value-date={@day_data.date}
                  class="group inline-flex h-8 w-8 items-center justify-center rounded-full text-gray-400 hover:text-orange-600 dark:hover:text-orange-500 hover:bg-orange-50 dark:hover:bg-orange-900/20 hover:scale-110 transition-all duration-200"
                  title="Justificar Ausência"
                >
                  <.icon name="hero-document-plus" class="size-5" />
                </button>
              <% end %>

              <button
                phx-click="abrir_novo_ponto"
                class="inline-flex h-8 w-8 items-center justify-center rounded-full text-gray-400 hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/30 dark:hover:text-indigo-400 transition-colors"
                title="Adicionar ponto manual"
              >
                <.icon name="hero-plus-circle" class="size-5" />
              </button>
          <% end %>
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
      <.header>
        Corrigir Registro
        <:subtitle>
          Ajuste ou invalide o registro de ponto selecionado.
        </:subtitle>
      </.header>

      <.simple_form for={@form} phx-submit="salvar_edicao">
        <div class="rounded-md bg-gray-50 dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700 p-4 mb-4 text-sm">
          <div class="flex justify-between items-center mb-1">
            <span class="text-gray-500 dark:text-zinc-400">Horário Original:</span>
            <span class="font-mono font-bold text-gray-900 dark:text-zinc-100">
              {@editing_clock_in.timestamp
              |> DateTime.shift_zone!("America/Sao_Paulo")
              |> Calendar.strftime("%d/%m/%Y - %H:%M")}
            </span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-gray-500 dark:text-zinc-400">Tipo Atual:</span>
            <span class="font-medium text-gray-900 dark:text-zinc-100">
              {format_clock_in_type(@editing_clock_in.type)}
            </span>
          </div>
        </div>

        <.input
          field={@form[:type]}
          type="select"
          label="Novo Tipo"
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
          prompt="Selecione um motivo..."
          options={[
            {"Esquecimento", :esquecimento},
            {"Problema Técnico", :problema_tecnico},
            {"Atestado Médico", :atestado_medico},
            {"Hora Extra Autorizada", :hora_extra_autorizada},
            {"Outros", :outros}
          ]}
          required
        />

        <.input
          field={@form[:observation]}
          type="textarea"
          label="Observações"
          placeholder="Detalhes adicionais..."
        />

        <:actions>
          <.button class="w-full">Salvar Correção</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  @doc """
  Modal para criação manual de ponto (Administrador).
  """
  attr :form, :map, required: true

  def create_modal(assigns) do
    ~H"""
    <.modal id="modal-novo-ponto" show on_cancel={JS.push("fechar_modal_criacao")}>
      <.header>
        Adicionar Ponto Manual
        <:subtitle>Insira um registro esquecido ou não contabilizado.</:subtitle>
      </.header>

      <.simple_form for={@form} phx-submit="salvar_novo_ponto">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:type]}
            type="select"
            label="Tipo"
            prompt="Selecione..."
            options={[
              {"Entrada", :entrada},
              {"Saída", :saida},
              {"Ida para Almoço", :ida_almoco},
              {"Volta do Almoço", :retorno_almoco}
            ]}
            required
          />

          <.input
            field={@form[:timestamp]}
            type="datetime-local"
            label="Data e Hora"
            required
          />
        </div>

        <div class="pt-2 border-t border-gray-100 dark:border-zinc-800 mt-2">
          <p class="text-xs font-semibold uppercase text-gray-500 mb-3 tracking-wider">Auditoria</p>

          <.input
            field={@form[:justification]}
            type="select"
            label="Motivo da Inclusão"
            prompt="Selecione..."
            options={[
              {"Esquecimento", :esquecimento},
              {"Problema Técnico", :problema_tecnico},
              {"Outros", :outros}
            ]}
            required
          />

          <.input
            field={@form[:observation]}
            type="textarea"
            label="Observação"
            placeholder="Detalhes sobre a inclusão manual..."
          />
        </div>

        <:actions>
          <.button class="w-full">Criar Registro</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  @doc """
  Modal para abonar uma falta.
  """
  attr :form, :map, required: true
  attr :date, Date, required: true

  def absence_modal(assigns) do
    ~H"""
    <.modal id="modal-abono" show on_cancel={JS.push("fechar_modal_abono")}>
      <.header>
        Justificar Ausência
        <:subtitle>
          Abonar falta do dia <span class="font-bold text-indigo-600 dark:text-indigo-400"><%= Calendar.strftime(@date, "%d/%m/%Y") %></span>.
        </:subtitle>
      </.header>

      <.simple_form for={@form} phx-submit="salvar_abono">
        <.input field={@form[:date]} type="hidden" value={@date} />

        <.input
          field={@form[:reason]}
          type="select"
          label="Motivo Legal"
          prompt="Selecione o motivo..."
          options={[
            {"Atestado Médico", "atestado_medico"},
            {"Folga Compensatória", "folga_banco"},
            {"Feriado Local", "feriado_local"},
            {"Licença Remunerada", "licenca"},
            {"Outros", "outros"}
          ]}
          required
        />

        <.input
          field={@form[:observation]}
          type="textarea"
          label="Detalhamento / CID"
          placeholder="Descreva detalhes adicionais para auditoria..."
        />

        <:actions>
          <.button class="w-full">Confirmar Abono</.button>
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

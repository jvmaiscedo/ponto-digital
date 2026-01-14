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
      <td class="px-4 py-2 whitespace-nowrap text-right text-sm font-medium">
        <div class="flex items-center justify-end gap-2">
          <%= if @day_data.abono do %>
            <span
              class="inline-flex items-center gap-1 rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20 dark:bg-green-900/30 dark:text-green-400 dark:ring-green-500/30 cursor-help"
              title={@day_data.abono.reason}
            >
              <.icon name="hero-check-circle-mini" class="size-3" /> Abonado
            </span>

            <button
              phx-click="remover_abono"
              phx-value-id={@day_data.abono.id}
              data-confirm="Tem certeza que deseja cancelar este abono? A falta voltará a ser cobrada."
              class="text-gray-400 hover:text-red-500 transition-colors p-1 rounded-md hover:bg-gray-100 dark:hover:bg-zinc-800"
              aria-label="Remover Abono"
              title="Cancelar Abono"
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          <% else %>
            <%= if @day_data.saldo_minutos < 0 do %>
              <button
                phx-click="abrir_abono"
                phx-value-date={@day_data.date}
                class="group flex items-center gap-1 rounded-full bg-yellow-50 px-3 py-1 text-xs font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20 hover:bg-yellow-100 transition-all dark:bg-yellow-900/30 dark:text-yellow-500 dark:ring-yellow-500/30 dark:hover:bg-yellow-900/50"
              >
                <.icon
                  name="hero-scale"
                  class="size-3 text-yellow-600 dark:text-yellow-500 group-hover:text-yellow-800"
                /> Justificar
              </button>
            <% else %>
              <button
                phx-click="abrir_novo_ponto"
                class="text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
                title="Adicionar Ponto Manual"
              >
                <.icon name="hero-plus-circle" class="size-5" />
              </button>
            <% end %>
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

  @doc """
  Modal para criação manual de ponto (Administrador).
  """
  attr :form, :map, required: true

  def create_modal(assigns) do
    ~H"""
    <.modal id="modal-novo-ponto" show on_cancel={JS.push("fechar_modal_criacao")}>
      <h2 class="text-lg font-bold text-gray-900 dark:text-zinc-100 mb-4">
        Adicionar Ponto Manualmente
      </h2>
      <p class="text-sm text-gray-500 mb-4">
        Utilize para inserir registros esquecidos.
      </p>

      <.simple_form for={@form} phx-submit="salvar_novo_ponto">
        <.input
          field={@form[:type]}
          type="select"
          label="Tipo do Registro"
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

        <div class="border-t border-gray-200 dark:border-zinc-700 my-4 pt-4">
          <p class="text-sm font-medium text-gray-900 dark:text-zinc-100 mb-2">Auditoria</p>

          <.input
            field={@form[:justification]}
            type="select"
            label="Motivo da Inclusão"
            prompt="Selecione..."
            options={[
              {"Esquecimento", :esquecimento},
              {"Problema Técnico (Relógio)", :problema_tecnico},
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
      <div class="flex items-start gap-4 mb-6">
        <div class="flex-none p-2 rounded-full bg-yellow-50 dark:bg-yellow-900/30 text-yellow-600 dark:text-yellow-500">
          <.icon name="hero-clipboard-document-check" class="size-6" />
        </div>
        <div>
          <h2 class="text-lg font-semibold text-gray-900 dark:text-zinc-100">
            Justificar Ausência
          </h2>
          <p class="text-sm text-gray-500 dark:text-zinc-400 mt-1">
            Você está abonando a falta do dia:
          </p>
          <div class="mt-2 inline-flex items-center px-3 py-1 rounded-md bg-gray-100 dark:bg-zinc-800 border border-gray-200 dark:border-zinc-700">
            <.icon name="hero-calendar" class="size-4 text-gray-500 mr-2" />
            <span class="font-mono font-bold text-gray-900 dark:text-zinc-200">
              {Calendar.strftime(@date, "%d/%m/%Y")}
            </span>
          </div>
        </div>
      </div>

      <.simple_form for={@form} phx-submit="salvar_abono" class="space-y-6">
        <.input field={@form[:date]} type="hidden" value={@date} />

        <div class="bg-gray-50 dark:bg-zinc-800/50 p-4 rounded-lg border border-gray-200 dark:border-zinc-700 space-y-4">
          <.input
            field={@form[:reason]}
            type="select"
            label="Motivo Legal"
            prompt="Selecione o motivo..."
            options={[
              {"Atestado Médico", "atestado_medico"},
              {"Folga Compensatória", "folga_banco"},
              {"Feriado Local", "feriado_local"},
              {"Licença Remunerada (Luto/Gala)", "licenca"},
              {"Outros", "outros"}
            ]}
            required
            class="!bg-white dark:!bg-zinc-900"
          />

          <.input
            field={@form[:observation]}
            type="textarea"
            label="Detalhamento / CID"
            placeholder="Descreva detalhes adicionais para auditoria..."
            class="min-h-[80px] !bg-white dark:!bg-zinc-900"
          />
        </div>

        <:actions>
          <div class="flex w-full gap-3">
            <button
              type="button"
              phx-click={JS.push("fechar_modal_abono")}
              class="flex-1 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 shadow-sm hover:bg-gray-50 dark:bg-zinc-800 dark:text-zinc-300 dark:border-zinc-600 dark:hover:bg-zinc-700"
            >
              Cancelar
            </button>
            <button
              type="submit"
              class="flex-1 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Confirmar Abono
            </button>
          </div>
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

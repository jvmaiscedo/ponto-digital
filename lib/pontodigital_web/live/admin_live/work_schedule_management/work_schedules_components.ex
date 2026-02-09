defmodule PontodigitalWeb.AdminLive.WorkScheduleManagement.WorkScheduleComponents do
  use PontodigitalWeb, :html

  @doc """
  Cabeçalho da página com título e ações, similar ao de funcionários.
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="md:flex md:items-center md:justify-between mb-8">
      <div class="min-w-0 flex-1">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight dark:text-zinc-100">
          <%= @title %>
        </h2>
        <p :if={@subtitle} class="mt-2 text-sm text-gray-500 dark:text-zinc-400">
          <%= @subtitle %>
        </p>
      </div>
      <div class="mt-4 flex md:ml-4 md:mt-0">
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  @doc """
  Badge estilizado para os dias da semana.
  """
  attr :days, :list, required: true

  def work_days_badge(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-1">
      <%= if @days == [] or is_nil(@days) do %>
        <span class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 dark:bg-gray-400/10 dark:text-gray-400 dark:ring-gray-400/20">
          Nenhum dia definido
        </span>
      <% else %>
        <%= for day <- format_days_list(@days) do %>
          <span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10 dark:bg-blue-400/10 dark:text-blue-400 dark:ring-blue-400/30">
            <%= day %>
          </span>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Botão de ação com ícone (Editar/Excluir).
  """
  attr :navigate, :string, default: nil
  attr :click, :string, default: nil
  attr :confirm, :string, default: nil
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :color, :string, default: "text-gray-400 hover:text-gray-500"

  def action_button(assigns) do
    ~H"""
    <%= if @navigate do %>
      <.link navigate={@navigate} class={["group flex items-center p-1 transition-colors", @color]} title={@label}>
        <.icon name={@icon} class="size-5" />
        <span class="sr-only"><%= @label %></span>
      </.link>
    <% else %>
      <button type="button" phx-click={@click} data-confirm={@confirm} class={["group flex items-center p-1 transition-colors", @color]} title={@label}>
        <.icon name={@icon} class="size-5" />
        <span class="sr-only"><%= @label %></span>
      </button>
    <% end %>
    """
  end

  @doc """
  Tabela estilizada (Wrapper).
  """
  slot :inner_block

  def styled_table_wrapper(assigns) do
    ~H"""
    <div class="mt-8 flow-root">
      <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg bg-white dark:bg-zinc-900 dark:ring-white/10">
            <table class="min-w-full divide-y divide-gray-300 dark:divide-zinc-700">
              <%= render_slot(@inner_block) %>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def format_days_list(days) do
    day_map = %{
      1 => "Seg", 2 => "Ter", 3 => "Qua", 4 => "Qui",
      5 => "Sex", 6 => "Sáb", 7 => "Dom"
    }

    days
    |> Enum.sort()
    |> Enum.map(&Map.get(day_map, &1))
  end

  def days_options do
    [
      {"Segunda-feira", 1}, {"Terça-feira", 2}, {"Quarta-feira", 3},
      {"Quinta-feira", 4}, {"Sexta-feira", 5}, {"Sábado", 6}, {"Domingo", 7}
    ]
  end
end

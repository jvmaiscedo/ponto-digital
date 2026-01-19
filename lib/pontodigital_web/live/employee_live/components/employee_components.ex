defmodule PontodigitalWeb.EmployeeLive.Components.EmployeeComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  @doc """
  Cabeçalho de página padrão, estilo Admin.
  """
  attr :employee, :map, required: true
  attr :title, :string, required: true
  attr :back_to, :string, default: nil

  def page_header(assigns) do
    ~H"""
    <header class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-8">
      <div>
        <div class="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400 mb-1">
          <.icon name="hero-user-circle" class="size-4" />
          <span>{@employee.full_name}</span>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100 sm:text-3xl">
          {@title}
        </h1>
      </div>

      <%= if @back_to do %>
        <div class="flex-none">
          <.link
            navigate={@back_to}
            class="group inline-flex items-center gap-1 rounded-lg px-3 py-2 text-sm font-semibold text-zinc-500 hover:bg-zinc-100 hover:text-zinc-900 dark:text-zinc-400 dark:hover:bg-zinc-800 dark:hover:text-zinc-200 transition-all"
          >
            <.icon
              name="hero-arrow-left"
              class="size-4 transition-transform group-hover:-translate-x-1"
            /> Voltar
          </.link>
        </div>
      <% end %>
    </header>
    """
  end

  @doc """
  Card de Navegação (Dashboard).
  Estilo "Stat Card" clicável.
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :to, :string, required: true

  def menu_card(assigns) do
    ~H"""
    <.link
      navigate={@to}
      class="group relative overflow-hidden rounded-xl bg-white dark:bg-zinc-900 p-6 shadow-sm ring-1 ring-zinc-900/5 transition-all hover:shadow-md hover:ring-zinc-900/10 dark:ring-white/10 dark:hover:ring-white/20"
    >
      <div class="absolute right-0 top-0 -mt-4 -mr-4 h-24 w-24 rounded-full bg-zinc-50 dark:bg-zinc-800 transition-all group-hover:scale-150">
      </div>

      <div class="relative">
        <div class="mb-4 inline-flex h-12 w-12 items-center justify-center rounded-lg bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 shadow-md group-hover:scale-110 transition-transform">
          <.icon name={@icon} class="size-6" />
        </div>

        <h3 class="text-lg font-semibold leading-7 text-zinc-900 dark:text-zinc-100">
          {@title}
        </h3>

        <p class="mt-2 text-sm leading-6 text-zinc-500 dark:text-zinc-400">
          {@description}
        </p>
      </div>
    </.link>
    """
  end
end

defmodule PontodigitalWeb.EmployeeLive.Components.DailyLogComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  attr :form, :map, required: true

  def daily_log_form(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl bg-white shadow-sm ring-1 ring-zinc-900/5 dark:bg-zinc-900 dark:ring-white/10">
      <div class="border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50 px-6 py-4">
        <h3 class="text-base font-semibold leading-6 text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
          <.icon name="hero-pencil-square" class="size-5 text-zinc-500" /> Atividades de Hoje
        </h3>
        <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
          Mantenha seu registro atualizado para o relatório mensal.
        </p>
      </div>

      <div class="p-6">
        <.form for={@form} phx-submit="save" class="flex flex-col gap-6">
          <.input type="hidden" field={@form[:employee_id]} />
          <.input type="hidden" field={@form[:date]} />

          <div>
            <.input
              field={@form[:description]}
              type="textarea"
              label="Descrição Detalhada"
              placeholder="- Daily Meeting&#10;- Desenvolvimento do módulo X..."
              class="block w-full rounded-lg border-zinc-200 py-3 text-zinc-900 shadow-sm focus:border-indigo-600 focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-zinc-800 dark:border-zinc-700 dark:text-white min-h-[200px]"
            />
          </div>

          <div class="flex items-center justify-end gap-x-6 border-t border-zinc-900/10 pt-6 dark:border-white/10">
            <button
              type="button"
              class="text-sm font-semibold leading-6 text-zinc-900 dark:text-zinc-100 hover:underline"
            >
              Cancelar
            </button>
            <button
              type="submit"
              class="rounded-md bg-zinc-900 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
            >
              Salvar Registro
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end

defmodule PontodigitalWeb.AdminLive.HolidayManagement.HolidayComponents do
  @moduledoc """
  Componentes visuais para a gestão de feriados.
  Separa a UI da lógica do LiveView.
  """
  use Phoenix.Component
  use PontodigitalWeb, :html

  @doc """
  Formulário de cadastro de feriado (Estilo Card).
  """
  attr :form, :map, required: true

  def holiday_form(assigns) do
    ~H"""
    <div class="rounded-xl bg-white dark:bg-zinc-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-white/10">
      <div class="border-b border-gray-200 dark:border-zinc-700 px-6 py-4">
        <h2 class="text-base font-semibold leading-7 text-gray-900 dark:text-white">
          Adicionar Feriado
        </h2>
        <p class="mt-1 text-xs text-gray-500 dark:text-zinc-400">
          Cadastre datas comemorativas para isenção automática.
        </p>
      </div>

      <div class="p-6">
        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
          <div>
            <.input
              field={@form[:date]}
              type="date"
              label="Data do Feriado"
              required
              class="block w-full rounded-md border-0 bg-transparent py-1.5 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-zinc-700 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            />
          </div>

          <div>
            <.input
              field={@form[:name]}
              type="text"
              label="Nome / Descrição"
              placeholder="Ex: Aniversário da Cidade"
              required
              class="block w-full rounded-md border-0 bg-transparent py-1.5 text-gray-900 dark:text-white shadow-sm ring-1 ring-inset ring-gray-300 dark:ring-zinc-700 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            />
          </div>

          <div class="pt-2">
            <button
              type="submit"
              class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-all"
            >
              Salvar Feriado
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Tabela de listagem de feriados.
  """
  attr :holidays, :list, required: true

  def holiday_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 shadow-sm">
      <table class="min-w-full divide-y divide-gray-200 dark:divide-zinc-700">
        <thead class="bg-gray-50 dark:bg-zinc-900/50">
          <tr>
            <th
              scope="col"
              class="px-6 py-4 text-left text-xs font-medium uppercase tracking-wider text-gray-500 dark:text-zinc-400"
            >
              Data
            </th>
            <th
              scope="col"
              class="px-6 py-4 text-left text-xs font-medium uppercase tracking-wider text-gray-500 dark:text-zinc-400"
            >
              Descrição
            </th>
            <th scope="col" class="relative px-6 py-4">
              <span class="sr-only">Ações</span>
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200 dark:divide-zinc-700 bg-white dark:bg-zinc-800">
          <tr
            :for={holiday <- @holidays}
            class="group hover:bg-gray-50 dark:hover:bg-zinc-700/30 transition-colors"
          >
            <td class="whitespace-nowrap px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="flex flex-col items-center justify-center rounded-lg bg-gray-100 dark:bg-zinc-700 p-2 w-12 h-12 border border-gray-200 dark:border-zinc-600">
                  <span class="text-xs font-bold text-gray-500 dark:text-zinc-400 uppercase">
                    {Calendar.strftime(holiday.date, "%b")}
                  </span>
                  <span class="text-lg font-bold text-gray-900 dark:text-white leading-none">
                    {Calendar.strftime(holiday.date, "%d")}
                  </span>
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">
                    {Calendar.strftime(holiday.date, "%Y")}
                  </p>
                  <p class="text-xs text-gray-500 dark:text-zinc-400">
                    {dia_da_semana(holiday.date)}
                  </p>
                </div>
              </div>
            </td>
            <td class="whitespace-nowrap px-6 py-4 text-sm font-medium text-gray-700 dark:text-zinc-300 group-hover:text-gray-900 dark:group-hover:text-white">
              {holiday.name}
            </td>
            <td class="whitespace-nowrap px-6 py-4 text-right text-sm font-medium">
              <button
                phx-click="delete"
                phx-value-id={holiday.id}
                data-confirm="Tem certeza que deseja remover este feriado?"
                class="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors p-2 rounded-full hover:bg-red-50 dark:hover:bg-red-900/20"
                aria-label="Excluir"
              >
                <.icon name="hero-trash" class="size-5" />
              </button>
            </td>
          </tr>

          <tr :if={@holidays == []}>
            <td colspan="3" class="px-6 py-12 text-center text-sm text-gray-500 dark:text-zinc-400">
              <div class="flex flex-col items-center justify-center">
                <.icon
                  name="hero-calendar-days"
                  class="size-10 text-gray-300 dark:text-zinc-600 mb-2"
                />
                <p>Nenhum feriado cadastrado ainda.</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # Helper visual para traduzir dia da semana
  defp dia_da_semana(date) do
    case Calendar.strftime(date, "%A") do
      "Monday" -> "Segunda-feira"
      "Tuesday" -> "Terça-feira"
      "Wednesday" -> "Quarta-feira"
      "Thursday" -> "Quinta-feira"
      "Friday" -> "Sexta-feira"
      "Saturday" -> "Sábado"
      "Sunday" -> "Domingo"
      _ -> ""
    end
  end
end

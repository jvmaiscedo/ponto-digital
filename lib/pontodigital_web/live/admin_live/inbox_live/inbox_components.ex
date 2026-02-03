defmodule PontodigitalWeb.AdminLive.InboxLive.InboxComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  import PontodigitalWeb.CoreComponents

  attr :messages, :list, required: true
  attr :meta, :map, required: true

def messages_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm flex flex-col">
      <Flop.Phoenix.table
        items={@messages}
        meta={@meta}
        path={~p"/admin/inbox"}
        row_click={fn {_id, message} -> JS.navigate(~p"/admin/inbox/#{message.id}") end}
        opts={[
          table_attrs: [class: "min-w-full divide-y divide-gray-200 dark:divide-zinc-700"],
          thead_attrs: [class: "bg-gray-50 dark:bg-zinc-900"],
          thead_th_attrs: [class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-left text-gray-500 dark:text-zinc-400"],
          tbody_attrs: [class: "bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700", id: "inbox-messages", "phx-update": "stream"],
          tbody_tr_attrs: [class: "hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors cursor-pointer group"],
          tbody_td_attrs: [class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"]
        ]}
      >
        <:col :let={{_id, message}} label="Data" field={:context_date}
          thead_th_attrs={[class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"]}
        >
          <div class="text-center font-medium text-gray-900 dark:text-zinc-100">
            {Calendar.strftime(message.context_date, "%d/%m/%Y")}
          </div>
        </:col>

        <:col :let={{_id, message}} label="Categoria" field={:category}
          thead_th_attrs={[class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"]}
        >
          <div class="flex justify-center">
            <span class={"inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset " <> category_badge_class(message.category)}>
              {humanize_category(message.category)}
            </span>
          </div>
        </:col>

        <:col :let={{_id, message}} label="Funcionário">
          <div class="flex items-center gap-3">
            <div class="h-8 w-8 rounded-full bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-xs font-bold text-indigo-600 dark:text-indigo-400 ring-1 ring-indigo-600/10">
              {if message.employee, do: String.at(message.employee.full_name, 0), else: "S"}
            </div>
            <span class="font-medium text-gray-900 dark:text-zinc-100">
              {if message.employee, do: message.employee.full_name, else: "Sistema"}
            </span>
          </div>
        </:col>

        <:col :let={{_id, message}} label="Mensagem" field={:content}>
          <div class="truncate max-w-[240px]" title={message.content}>
            {message.content}
          </div>
        </:col>

        <:col :let={{_id, message}} label="Status" field={:read_at}
          thead_th_attrs={[class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"]}
        >
          <div class="flex justify-center">
            <%= if message.read_at do %>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 ring-1 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-400 dark:ring-emerald-400/20">
                <.icon name="hero-check-circle-mini" class="size-3.5" />
                Lido
              </span>
            <% else %>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-700 ring-1 ring-blue-700/10 dark:bg-blue-400/10 dark:text-blue-400 dark:ring-blue-400/30">
                <.icon name="hero-envelope-mini" class="size-3.5" />
                Novo
              </span>
            <% end %>
          </div>
        </:col>

        <:col :let={{_id, message}} label="Ações"
          thead_th_attrs={[class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-right text-gray-500 dark:text-zinc-400"]}
        >
          <div class="flex items-center justify-end gap-2" onclick="event.stopPropagation()">
            <%= unless message.read_at do %>
              <button
                phx-click="mark_as_read"
                phx-value-id={message.id}
                class="p-1.5 rounded-full text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
                title="Marcar como lido"
              >
                <.icon name="hero-check" class="size-5" />
              </button>
            <% end %>

            <%= if message.attachment_path do %>
              <.link
                href={message.attachment_path}
                target="_blank"
                class="p-1.5 rounded-full text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 transition-colors"
                title="Ver anexo"
              >
                <.icon name="hero-paper-clip" class="size-5" />
              </.link>
            <% end %>

            <.link navigate={~p"/admin/inbox/#{message.id}"} class="p-1.5 rounded-full text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-zinc-700 transition-colors">
              <.icon name="hero-chevron-right" class="size-5" />
            </.link>
          </div>
        </:col>
      </Flop.Phoenix.table>

      <div class="p-4 border-t border-gray-200 dark:border-zinc-700 bg-gray-50 dark:bg-zinc-900 flex justify-center">
        <Flop.Phoenix.pagination meta={@meta} path={~p"/admin/inbox"} />
      </div>
    </div>
    """
  end

  defp category_badge_class(:esquecimento), do: "bg-yellow-50 text-yellow-800 ring-yellow-600/20 dark:bg-yellow-400/10 dark:text-yellow-500 dark:ring-yellow-400/20"
  defp category_badge_class(:atestado), do: "bg-purple-50 text-purple-700 ring-purple-700/10 dark:bg-purple-400/10 dark:text-purple-400 dark:ring-purple-400/30"
  defp category_badge_class(:ferias), do: "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-400/10 dark:text-green-400 dark:ring-green-400/30"
  defp category_badge_class(_), do: "bg-gray-50 text-gray-600 ring-gray-500/10 dark:bg-gray-400/10 dark:text-gray-400 dark:ring-gray-400/20"
  defp humanize_category(atom), do: atom |> to_string() |> String.replace("_", " ") |> String.capitalize()
end

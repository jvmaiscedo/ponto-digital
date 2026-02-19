defmodule PontodigitalWeb.AdminLive.InboxLive.InboxComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  import PontodigitalWeb.CoreComponents

  attr :messages, :list, required: true
  attr :meta, :map, required: true
def messages_table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-zinc-700 shadow-sm flex flex-col">
      <% return_to = if @meta, do: Flop.Phoenix.build_path(~p"/admin/inbox", @meta), else: ~p"/admin/inbox" %>
      <Flop.Phoenix.table
        items={@messages}
        meta={@meta}
        path={~p"/admin/inbox"}
        row_click={fn {_id, message} -> JS.navigate(~p"/admin/inbox/#{message.id}?#{[return_to: return_to]}") end}
        opts={[
          table_attrs: [class: "min-w-full divide-y divide-gray-200 dark:divide-zinc-700"],
          thead_attrs: [class: "bg-gray-50 dark:bg-zinc-900"],
          thead_th_attrs: [
            class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-left text-gray-500 dark:text-zinc-400"
          ],
          tbody_attrs: [
            class: "bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-zinc-700",
            id: "inbox-messages",
            "phx-update": "stream"
          ],
          tbody_tr_attrs: [
            class: "hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors cursor-pointer group"
          ],
          tbody_td_attrs: [
            class: "px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"
          ]
        ]}
      >
        <:col
          :let={{_id, message}}
          label="Data"
          field={:context_date}
          thead_th_attrs={[
            class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"
          ]}
        >
          <div class="text-center font-medium text-gray-900 dark:text-zinc-100">
            {Calendar.strftime(message.context_date, "%d/%m/%Y")}
          </div>
        </:col>

        <:col
          :let={{_id, message}}
          label="Categoria"
          field={:category}
          thead_th_attrs={[
            class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"
          ]}
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

        <:col
          :let={{_id, message}}
          label="Status"
          field={:read_at}
          thead_th_attrs={[
            class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400"
          ]}
        >
          <div class="flex justify-center">
            <%= if message.read_at do %>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 ring-1 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-400 dark:ring-emerald-400/20">
                <.icon name="hero-check-circle-mini" class="size-3.5" /> Lido
              </span>
            <% else %>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-50 text-blue-700 ring-1 ring-blue-700/10 dark:bg-blue-400/10 dark:text-blue-400 dark:ring-blue-400/30">
                <.icon name="hero-envelope-mini" class="size-3.5" /> Novo
              </span>
            <% end %>
          </div>
        </:col>

        <:col
          :let={{_id, message}}
          label="Ações"
          thead_th_attrs={[
            class: "px-6 py-3 text-xs font-medium uppercase tracking-wider text-center text-gray-500 dark:text-zinc-400 w-[140px]"
          ]}
        >
          <div class="flex items-center justify-end gap-2 shrink-0" onclick="event.stopPropagation()">
            <%= unless message.read_at do %>
              <button
                phx-click="mark_as_read"
                phx-value-id={message.id}
                class="p-1.5 rounded-full text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-zinc-700 transition-colors"
                title="Marcar como lido"
              >
                <.icon name="hero-check" class="size-5" />
              </button>
            <% end %>

            <%= if message.attachment_path do %>
              <.link
                href={message.attachment_path}
                target="_blank"
                class="p-1.5 rounded-full text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-zinc-700 transition-colors"
                title="Ver anexo"
              >
                <.icon name="hero-paper-clip" class="size-5" />
              </.link>
            <% end %>

             <.link
              navigate={~p"/admin/inbox/#{message.id}?#{[return_to: return_to]}"}
              class="p-1.5 rounded-full text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-zinc-700 transition-colors"
            >
              <.icon name="hero-chevron-right" class="size-5" />
            </.link>
          </div>
        </:col>
      </Flop.Phoenix.table>

      <div class="p-4 border-t border-gray-200 dark:border-zinc-700 bg-gray-50 dark:bg-zinc-900 flex justify-center [&_nav]:flex [&_nav]:justify-center [&_ul]:flex [&_ul]:flex-wrap [&_ul]:gap-1 [&_ul]:items-center [&_a]:px-3 [&_a]:py-1 [&_a]:rounded-md [&_a]:text-sm [&_a]:font-medium [&_a]:text-gray-600 dark:[&_a]:text-gray-400 [&_a]:transition-all [&_a:hover]:bg-white dark:[&_a:hover]:bg-zinc-800 [&_a:hover]:text-indigo-600 dark:[&_a:hover]:text-indigo-400 [&_a:hover]:shadow-sm [&_a:hover]:ring-1 [&_a:hover]:ring-gray-200 dark:[&_a:hover]:ring-zinc-700 [&_span]:px-3 [&_span]:py-1 [&_span]:text-sm [&_span.current]:font-bold [&_span.current]:bg-indigo-600 [&_span.current]:text-white [&_span.current]:rounded-md [&_span.current]:shadow-sm [&_span.disabled]:text-gray-300 dark:[&_span.disabled]:text-zinc-600 [&_span.disabled]:cursor-not-allowed">
        <Flop.Phoenix.pagination
          meta={@meta}
          path={~p"/admin/inbox"}
        />
      </div>
    </div>
    """
  end

  attr :target, :string, default: "/admin/inbox"
  attr :label, :string, default: "Voltar para Caixa de Entrada"

  def back_link(assigns) do
    ~H"""
    <div class="mb-6">
      <.link
        navigate={@target}
        class="inline-flex items-center gap-2 text-sm font-medium text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-200 transition-colors"
      >
        <.icon name="hero-arrow-left" class="size-4" />
        {@label}
      </.link>
    </div>
    """
  end

  attr :message, :map, required: true

  def message_header(assigns) do
    ~H"""
    <div class="mb-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-zinc-100">
          Detalhes da Solicitação
        </h1>
        <p class="text-sm text-gray-500 dark:text-zinc-400 mt-1">
          Recebida em {Calendar.strftime(@message.inserted_at, "%d/%m/%Y às %H:%M")}
        </p>
      </div>

      <span class={"px-3 py-1.5 rounded-full text-sm font-medium ring-1 ring-inset shadow-sm " <> category_badge_class(@message.category)}>
        {humanize_category(@message.category)}
      </span>
    </div>
    """
  end

  attr :message, :map, required: true

  def message_details_card(assigns) do
    ~H"""
    <div class="bg-white dark:bg-zinc-800 shadow-sm rounded-xl border border-gray-200 dark:border-zinc-700 overflow-hidden">
      <div class="px-6 py-4 border-b border-gray-200 dark:border-zinc-700 flex flex-col sm:flex-row sm:items-center justify-between bg-gray-50/50 dark:bg-zinc-900/50 gap-4">
        <div class="flex items-center gap-4">
          <div class="h-10 w-10 rounded-full bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-600 dark:text-indigo-400 ring-1 ring-indigo-600/10">
            <.icon name="hero-user" class="size-5" />
          </div>
          <div>
            <h3 class="text-sm font-bold text-gray-900 dark:text-zinc-100">
              {if @message.employee, do: @message.employee.full_name, else: "Sistema"}
            </h3>
            <p class="text-xs text-gray-500 dark:text-zinc-400">
              {if @message.employee, do: @message.employee.position, else: "Automático"}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-4 sm:gap-6">
          <div class="flex flex-col items-end">
            <span class="text-xs text-gray-500 dark:text-zinc-500 uppercase tracking-wider font-semibold">
              Data do Ocorrido
            </span>
            <span class="text-sm font-bold text-gray-900 dark:text-zinc-100">
              {Calendar.strftime(@message.context_date, "%d/%m/%Y")}
            </span>
          </div>

          <div class="h-8 w-px bg-gray-200 dark:bg-zinc-700 hidden sm:block"></div>

          <%= if @message.read_at do %>
            <div class="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/20 px-3 py-1.5 rounded-full ring-1 ring-inset ring-emerald-600/20">
              <.icon name="hero-check-circle-solid" class="size-4" />
              <span class="text-xs font-bold uppercase">Lida</span>
            </div>
          <% else %>
            <div class="flex items-center gap-1.5 text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20 px-3 py-1.5 rounded-full ring-1 ring-inset ring-blue-600/20">
              <.icon name="hero-envelope" class="size-4" />
              <span class="text-xs font-bold uppercase">Nova</span>
            </div>
          <% end %>
        </div>
      </div>

      <div class="px-6 py-8 bg-white dark:bg-zinc-800 flex flex-col items-center">
        <h3 class="text-xs font-bold text-gray-400 dark:text-zinc-500 uppercase tracking-widest mb-4 text-center">
          Mensagem
        </h3>

        <div class="w-full bg-gray-50 dark:bg-zinc-900/50 border border-gray-200 dark:border-zinc-700 rounded-lg p-6 shadow-sm">
          <div class="prose prose-zinc prose-sm dark:prose-invert max-w-none text-gray-700 dark:text-zinc-300 leading-relaxed text-center sm:text-left">
            {@message.content}
          </div>
        </div>
      </div>

      <%= if @message.attachment_path do %>
        <div class="px-6 pb-8 bg-white dark:bg-zinc-800 flex flex-col items-center">
          <h4 class="text-xs font-bold text-gray-400 dark:text-zinc-500 uppercase tracking-widest mb-4 text-center">
            Anexo
          </h4>

          <a
            href={@message.attachment_path}
            target="_blank"
            class="inline-flex items-center gap-3 px-5 py-3 rounded-lg border border-gray-200 dark:border-zinc-600 bg-white dark:bg-zinc-800 hover:bg-indigo-50 dark:hover:bg-zinc-700 hover:border-indigo-200 dark:hover:border-indigo-500/50 transition-all group shadow-sm ring-1 ring-gray-900/5"
          >
            <div class="p-1 rounded bg-indigo-100 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 group-hover:scale-110 transition-transform">
              <.icon name="hero-paper-clip" class="size-5" />
            </div>
            <span class="text-sm font-semibold text-gray-700 dark:text-zinc-200 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
              Visualizar Documento
            </span>
            <.icon
              name="hero-arrow-top-right-on-square"
              class="size-4 text-gray-400 group-hover:text-indigo-500 ml-1 transition-colors"
            />
          </a>
        </div>
      <% end %>
    </div>
    """
  end

  defp category_badge_class(:esquecimento),
    do:
      "bg-yellow-50 text-yellow-800 ring-yellow-600/20 dark:bg-yellow-400/10 dark:text-yellow-500 dark:ring-yellow-400/20"

  defp category_badge_class(:atestado),
    do:
      "bg-purple-50 text-purple-700 ring-purple-700/10 dark:bg-purple-400/10 dark:text-purple-400 dark:ring-purple-400/30"

  defp category_badge_class(:ferias),
    do:
      "bg-green-50 text-green-700 ring-green-600/20 dark:bg-green-400/10 dark:text-green-400 dark:ring-green-400/30"

  defp category_badge_class(_),
    do:
      "bg-gray-50 text-gray-600 ring-gray-500/10 dark:bg-gray-400/10 dark:text-gray-400 dark:ring-gray-400/20"

  defp humanize_category(atom),
    do: atom |> to_string() |> String.replace("_", " ") |> String.capitalize()
end

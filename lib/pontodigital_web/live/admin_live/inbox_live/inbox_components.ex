defmodule PontodigitalWeb.AdminLive.InboxLive.InboxComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  @doc """
  Tabela de mensagens do Inbox.
  """
  attr :messages, :list, required: true

  def messages_table(assigns) do
    ~H"""
    <.table id="inbox-messages" rows={@messages}>
      <:col :let={{_id, message}} label="Data">
        {Calendar.strftime(message.context_date, "%d/%m/%Y")}
      </:col>

      <:col :let={{_id, message}} label="Categoria">
        <span class={"badge badge-sm " <> category_badge_class(message.category)}>
          {String.capitalize(to_string(message.category))}
        </span>
      </:col>

      <:col :let={{_id, message}} label="Funcionário">
        <span class="font-semibold">
          {if message.employee, do: message.employee.full_name, else: "Sistema"}
        </span>
      </:col>

      <:col :let={{_id, message}} label="Mensagem">
        <div class="truncate max-w-xs text-zinc-600 dark:text-zinc-400" title={message.content}>
          {message.content}
        </div>
      </:col>

      <:col :let={{_id, message}} label="Status">
        <%= if message.read_at do %>
          <span class="badge badge-success badge-sm text-white gap-1">
            <.icon name="hero-check" class="size-3" /> Lido
          </span>
        <% else %>
          <span class="badge badge-warning badge-sm gap-1">
            <.icon name="hero-envelope" class="size-3" /> Novo
          </span>
        <% end %>
      </:col>

      <:action :let={{_id, message}}>
        <div class="flex items-center gap-2">
          <%= unless message.read_at do %>
            <.button
              phx-click="mark_as_read"
              phx-value-id={message.id}
              class="btn-ghost btn-xs text-blue-600 hover:bg-blue-50"
            >
              Marcar lido
            </.button>
          <% end %>

          <%= if message.attachment_path do %>
            <.link
              href={message.attachment_path}
              target="_blank"
              class="btn btn-ghost btn-xs text-zinc-500"
              title="Ver anexo"
            >
              <.icon name="hero-paper-clip" class="size-4" />
            </.link>
          <% end %>
        </div>
      </:action>
    </.table>
    """
  end

  defp category_badge_class(:esquecimento), do: "badge-warning"
  defp category_badge_class(:problema_tecnico), do: "badge-error text-white"
  defp category_badge_class(:atestado_medico), do: "badge-info text-white"
  defp category_badge_class(_), do: "badge-ghost"
end

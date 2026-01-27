defmodule PontodigitalWeb.EmployeeLive.Components.ClockInComponents do
  use Phoenix.Component
  use PontodigitalWeb, :html

  @doc """
  Grid que mostra todos os botões, desabilitando os inválidos.
  """
  attr :allowed_types, :list, required: true

  def clock_in_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
      <.smart_button type={:entrada} allowed={@allowed_types} />
      <.smart_button type={:ida_almoco} allowed={@allowed_types} />
      <.smart_button type={:retorno_almoco} allowed={@allowed_types} />
      <.smart_button type={:saida} allowed={@allowed_types} />
    </div>
    """
  end

  attr :type, :atom, required: true
  attr :allowed, :list, required: true

  def smart_button(assigns) do
    is_enabled = assigns.type in assigns.allowed

    config = get_button_config(assigns.type)

    assigns =
      assigns
      |> assign(config)
      |> assign(:disabled, !is_enabled)

    ~H"""
    <button
      disabled={@disabled}
      phx-click={unless @disabled, do: "registrar_ponto"}
      phx-value-type={@type}
      class={
        [
          "group relative flex flex-col items-start p-6 rounded-2xl border shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-offset-2",
          # Estilos Condicionais:
          if(@disabled,
            do: "bg-gray-100 border-gray-200 cursor-not-allowed opacity-60 grayscale",
            else: "hover:shadow-md hover:scale-[1.01] " <> color_classes(@color)
          )
        ]
      }
    >
      <div class={[
        "mb-4 p-3 rounded-xl shadow-inner transition-colors",
        if(@disabled, do: "bg-gray-200", else: "bg-white/20")
      ]}>
        <.icon
          name={@icon}
          class={[
            "size-8",
            if(@disabled, do: "text-gray-400", else: "text-white")
          ]}
        />
      </div>

      <span class={[
        "text-xl font-bold tracking-tight mb-1",
        if(@disabled, do: "text-gray-400", else: "text-white")
      ]}>
        {@label}
      </span>

      <span class={[
        "text-sm font-medium",
        if(@disabled, do: "text-gray-400", else: "text-white/80")
      ]}>
        {@description}
      </span>

      <div
        :if={!@disabled}
        class="absolute top-6 right-6 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <.icon name="hero-arrow-up-right" class="size-5 text-white/70" />
      </div>
    </button>
    """
  end

  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :description, :string, required: true
  attr :icon, :string, required: true
  attr :color, :string, required: true

  def action_button(assigns) do
    ~H"""
    <button
      phx-click="registrar_ponto"
      phx-value-type={@type}
      class={"group relative flex flex-col items-start p-6 rounded-2xl border shadow-sm transition-all hover:shadow-md hover:scale-[1.01] focus:outline-none focus:ring-2 focus:ring-offset-2 " <> color_classes(@color)}
    >
      <div class="mb-4 p-3 rounded-xl bg-white/20 shadow-inner">
        <.icon name={@icon} class="size-8 text-white" />
      </div>

      <span class="text-xl font-bold tracking-tight text-white mb-1">
        {@label}
      </span>

      <span class="text-sm font-medium text-white/80">
        {@description}
      </span>

      <div class="absolute top-6 right-6 opacity-0 group-hover:opacity-100 transition-opacity">
        <.icon name="hero-arrow-up-right" class="size-5 text-white/70" />
      </div>
    </button>
    """
  end

  defp get_button_config(:entrada) do
    %{
      type: "entrada",
      label: "Registrar Entrada",
      description: "Vamos começar o dia!",
      icon: "hero-arrow-right-end-on-rectangle",
      color: "emerald"
    }
  end

  defp get_button_config(:ida_almoco) do
    %{
      type: "ida_almoco",
      label: "Saída para Almoço",
      description: "Bom apetite!",
      icon: "hero-pause",
      color: "amber"
    }
  end

  defp get_button_config(:retorno_almoco) do
    %{
      # Atenção: Use o valor exato que seu backend espera (retorno_almoco vs volta_almoco)
      type: "retorno_almoco",
      label: "Volta do Almoço",
      description: "De volta ao trabalho",
      icon: "hero-play",
      color: "blue"
    }
  end

  defp get_button_config(:saida) do
    %{
      type: "saida",
      label: "Encerrar Expediente",
      description: "Até amanhã!",
      icon: "hero-arrow-left-start-on-rectangle",
      color: "rose"
    }
  end

  defp color_classes("emerald"),
    do: "bg-emerald-600 border-emerald-700 hover:bg-emerald-500 focus:ring-emerald-500"

  defp color_classes("amber"),
    do: "bg-amber-500 border-amber-600 hover:bg-amber-400 focus:ring-amber-500"

  defp color_classes("blue"),
    do: "bg-blue-600 border-blue-700 hover:bg-blue-500 focus:ring-blue-500"

  defp color_classes("rose"),
    do: "bg-rose-600 border-rose-700 hover:bg-rose-500 focus:ring-rose-500"

  defp color_classes(_), do: "bg-zinc-600 border-zinc-700 hover:bg-zinc-500 focus:ring-zinc-500"
end

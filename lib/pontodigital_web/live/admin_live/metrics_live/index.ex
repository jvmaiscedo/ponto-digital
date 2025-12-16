defmodule PontodigitalWeb.AdminLive.MetricsLive.Index do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Company

  @impl true
  def mount(_params, _session, socket) do
    total_funcionarios = Company.count_employees()

    {:ok,
     socket
     |> assign(total_funcionarios: total_funcionarios)}
  end
end

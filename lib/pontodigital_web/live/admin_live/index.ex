defmodule PontodigitalWeb.AdminLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company



  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    total_funcionarios = Company.count_employees()
    {:ok,
     socket
     |> assign(total_funcionarios: total_funcionarios)
     |> assign(current_user: current_user) }
  end
end

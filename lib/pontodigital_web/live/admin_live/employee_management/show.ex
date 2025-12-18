defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Show do
  use PontodigitalWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    employee = Pontodigital.Company.get_employee!(id)
    data_atual = Date.utc_today()

    {:ok,
     socket
     |> assign(employee: employee)
     |> assign(data_atual: data_atual)}
  end



end

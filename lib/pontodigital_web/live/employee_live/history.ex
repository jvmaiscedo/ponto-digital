defmodule PontodigitalWeb.EmployeeLive.History do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping

  @impl true
  def mount(_params, _session, socket) do
    clock_ins = Timekeeping.list_clock_ins_by_employee(socket.assigns.employee)

    {:ok, assign(socket, clock_ins: clock_ins)}
  end
end

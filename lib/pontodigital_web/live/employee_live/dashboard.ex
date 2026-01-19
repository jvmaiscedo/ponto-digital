defmodule PontodigitalWeb.EmployeeLive.Dashboard do
  use PontodigitalWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

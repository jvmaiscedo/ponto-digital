defmodule PontodigitalWeb.EmployeeLive.History do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping

  @impl true
  def mount(_params, _session, socket) do
    employee = socket.assigns.employee

    today = Date.utc_today()

    report = Timekeeping.get_monthly_report(employee, today)

    {:ok,
     socket
     |> assign(:selected_month, today.month)
     |> assign(:selected_year, today.year)
     |> assign(:report, report)
     |> assign(:report_modal, nil)}
  end

  @impl true
  def handle_event("filter", %{"month" => month, "year" => year}, socket) do
    employee = socket.assigns.employee
    {m, _} = Integer.parse(month)
    {y, _} = Integer.parse(year)

    target_date = Date.new!(y, m, 1)

    report = Timekeeping.get_monthly_report(employee, target_date)

    {:noreply,
     socket
     |> assign(:selected_month, m)
     |> assign(:selected_year, y)
     |> assign(:report, report)}
  end

  @impl true
  def handle_event("open_report_modal", %{"date" => date_str}, socket) do
    {:noreply, assign(socket, :report_modal, %{date: date_str})}
  end

  @impl true
  def handle_event("close_modal", _unsigned_params, socket) do
    {:noreply, assign(socket, :report_modal, nil)}
  end

  @impl true
  def handle_info({:report_created, msg}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, msg)
     |> assign(:report_modal, nil)}
  end
end

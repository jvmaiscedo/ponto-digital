defmodule PontodigitalWeb.EmployeeLive.DailyLog do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping
  alias PontodigitalWeb.EmployeeLive.Components.DailyLogComponents

  @impl true
  def mount(_params, _session, socket) do
    employee = socket.assigns.employee
    today = Date.utc_today()

    daily_log =
      Timekeeping.get_daily_log(employee.id, today) ||
        %Timekeeping.DailyLog{employee_id: employee.id, date: today}

    changeset = Timekeeping.DailyLog.changeset(daily_log, %{})

    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"daily_log" => log_params}, socket) do
    secure_params =
      Map.merge(
        log_params,
        %{
          "employee_id " => socket.assigns.employee.id,
          "date" => Date.utc_today()
        }
      )

    case Timekeeping.save_daily_log(secure_params) do
      {:ok, _log} ->
        {:noreply, put_flash(socket, :info, "Registro salvo com sucesso.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end

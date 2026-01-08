defmodule PontodigitalWeb.AdminLive.EmployeeManagement.Show do
  use PontodigitalWeb, :live_view
  alias Pontodigital.Timekeeping
  alias Pontodigital.Timekeeping.ClockInAdjustment
  alias Pontodigital.Company
  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, editing_clock_in: nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    data_atual = Date.utc_today()
    {:noreply, espelho_mes(socket, id, data_atual)}
  end

  @impl true
  def handle_event("alterar_ponto", %{"id" => id}, socket) do
    ponto = Timekeeping.get_clock_in!(id)

    changeset = Timekeeping.change_adjustment(%ClockInAdjustment{})

    {:noreply,
     assign(socket,
       editing_clock_in: ponto,
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("fechar_modal", _params, socket) do
    {:noreply, assign(socket, editing_clock_in: nil)}
  end

  @impl true
  def handle_event("salvar_edicao", %{"clock_in_adjustment" => params}, socket) do
    {:noreply, assign(socket, editing_clock_in: nil)}
  end

  @impl true
  def handle_event("mudar_periodo", %{"periodo" => periodo_str}, socket) do
    data_segura = parse_periodo_seguro(periodo_str)

    employee_id = socket.assigns.employee_id

    {:noreply, espelho_mes(socket, employee_id, data_segura)}
  end

  defp espelho_mes(socket, id, data) do
    timezone = "America/Sao_Paulo"

    mapa_pontos = Timekeeping.list_timesheet(id, data.year, data.month, timezone)

    primeiro_dia = Date.beginning_of_month(data)
    ultimo_dia = Date.end_of_month(data)
    dias_do_mes = Date.range(primeiro_dia, ultimo_dia)

    employee = Company.get_employee!(id)

    mes_input_str = Calendar.strftime(data, "%Y-%m")

    assign(socket,
      mapa_pontos: mapa_pontos,
      dias_do_mes: dias_do_mes,
      employee_id: id,
      employee: employee,
      employee_name: employee.full_name,
      mes_selecionado: mes_input_str
    )
  end

  defp parse_periodo_seguro(periodo_str) do
    case Date.from_iso8601("#{periodo_str}-01") do
      {:ok, data} -> data
      {:error, _reason} -> Date.utc_today()
    end
  end

  def dia_semana(data) do
    case Calendar.strftime(data, "%a") do
      "Mon" -> "Seg"
      "Tue" -> "Ter"
      "Wed" -> "Qua"
      "Thu" -> "Qui"
      "Fri" -> "Sex"
      "Sat" -> "Sáb"
      "Sun" -> "Dom"
    end
  end
end

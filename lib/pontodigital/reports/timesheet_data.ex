defmodule Pontodigital.Reports.TimesheetData do
  alias Pontodigital.{Timekeeping, Repo}

  def build(employee, month, year) do
    employee = Repo.preload(employee, :work_schedule)

    target_date = Date.new!(year, month, 1)

    report = Timekeeping.get_monthly_report(employee, target_date)

    %{
      company_name: "Pontodigital Tecnologia LTDA",
      company_cnpj: "00.000.000/0001-00",
      period: "#{format_month(month)}/#{year}",
      emitted_at: Calendar.strftime(Date.utc_today(), "%d/%m/%Y"),
      employee: %{
        name: employee.full_name,
        position: employee.position || "Colaborador"
      },
      total_balance: report.formatted_total,
      days: Enum.map(report.days, &format_day/1)
    }
  end

  defp format_day(day) do
    %{
      date: Calendar.strftime(day.date, "%d/%m"),
      entry: format_point(day.points[:entrada]),
      lunch: format_intervals(day.points[:ida_almoco], day.points[:retorno_almoco]),
      exit: format_point(day.points[:saida]),
      balance: day.saldo_visual,
      obs: format_obs(day)
    }
  end

  defp format_point(nil), do: "--"

  defp format_point(point) do
    point.original.timestamp
    |> DateTime.shift_zone!("America/Sao_Paulo")
    |> Calendar.strftime("%H:%M")
  end

  defp format_intervals(nil, nil), do: "--"
  defp format_intervals(p1, nil), do: format_point(p1)
  defp format_intervals(p1, p2), do: "#{format_point(p1)} - #{format_point(p2)}"

  defp format_obs(day) do
    cond do
      day.ferias -> "Férias"
      day.feriado -> "Feriado: #{day.feriado}"
      day.abono -> "Abonado: #{format_abono_reason(day.abono.reason)}"
      day.daily_log -> day.daily_log.description
      true -> ""
    end
  end

  defp format_month(m) do
    Enum.at(
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
      m - 1
    )
  end

  defp format_abono_reason(reason) do
    case reason do
      "atestado_medico" -> "Atestado Médico"
      "folga_banco" -> "Folga Compensatória"
      "feriado_local" -> "Feriado Local"
      "licenca" -> "Licença Remunerada"
      "outros" -> "Motivo não listado"
    end
  end
end

defmodule Pontodigital.Reports.TimesheetData do
  alias Pontodigital.{Timekeeping, Repo}


  def build(employee, month, year) do
    employee = Repo.preload(employee, :work_schedule)

    target_date = Date.new!(year, month, 1)

    report = Timekeeping.get_monthly_report(employee, target_date)

    %{
      company_name: "CIPEC - Laboratório Lindalva",
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

def build_weekly_payload(employee, month, year) do
    employee = Repo.preload(employee, :work_schedule)

    target_date = Date.new!(year, month, 1)


    report_data = Timekeeping.get_monthly_report(employee, target_date)

   days_of_month = Enum.filter(report_data.days, fn day ->
      day.date.month == month
    end)

    weeks = group_days_by_week(days_of_month)

    %{
      company_name: "Universidade Estadual do Sudoeste da Bahia - UESB",
      period_month: "#{format_month(month)}",
      period_year: "#{year}",
      emitted_at: Calendar.strftime(Date.utc_today(), "%d/%m/%Y"),
      employee: %{
        name: employee.full_name,
        position: employee.position || "Discente",
      },
      weeks: weeks
    }
  end

defp group_days_by_week(days) do
    days
    |> Enum.chunk_by(fn day ->
      {year, week} = Date.to_erl(day.date) |> :calendar.iso_week_number()
      {year, week}
    end)
    |> Enum.filter(fn week_days ->
      Enum.any?(week_days, fn day -> Date.day_of_week(day.date) <= 5 end)
    end)
    |> Enum.filter(fn week_days ->
      Enum.any?(week_days, &is_business_day?/1)
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {week_days, index} ->
      valid_business_days = Enum.filter(week_days, fn day ->
        is_business_day?(day)
      end)

      start_date = List.first(valid_business_days).date
      end_date = List.last(valid_business_days).date

      total_minutes_week = Enum.reduce(week_days, 0, fn day, acc ->
        acc + (day.trabalhado_minutos || 0)
      end)


      weekly_summary =
        week_days
        |> Enum.map(fn day ->
          if day.daily_log, do: day.daily_log.description, else: nil
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.reject(&(&1 == ""))

      %{
        label: "#{index}ª SEMANA",
        period: "#{Calendar.strftime(start_date, "%d/%m")} a #{Calendar.strftime(end_date, "%d/%m")}",
        total_hours: format_peti_hours(total_minutes_week),
        summary: weekly_summary
      }
    end)
  end

  defp is_business_day?(day) do
    Date.day_of_week(day.date) <= 5 and is_nil(day.feriado)
  end
  defp format_peti_hours(0), do: ""
  defp format_peti_hours(minutes) do
    hours = div(abs(minutes), 60)
    mins = rem(abs(minutes), 60)
    formatted = "#{String.pad_leading(to_string(hours), 2, "0")}:#{String.pad_leading(to_string(mins), 2, "0")}"
    if minutes < 0, do: "" , else: formatted
  end

  defp format_day(day) do
    %{
      date: Calendar.strftime(day.date, "%d/%m"),
      entry: format_point(day.points[:entrada]),
      lunch: format_intervals(day.points[:ida_almoco], day.points[:retorno_almoco]),
      exit: format_point(day.points[:saida]),
      balance: day.saldo_visual,
      daily_log: daily_log_check(day),
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
      day.abono -> "#{format_abono_reason(day.abono.reason)}"
      true -> ""
    end
  end

  defp format_month(m) do
    Enum.at(
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro),
      m - 1
    )
  end

  defp daily_log_check(day) do
    case day.daily_log do
      nil -> ""
      log -> log.description
    end
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

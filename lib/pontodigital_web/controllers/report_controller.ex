defmodule PontodigitalWeb.ReportController do
  use PontodigitalWeb, :controller

  alias Pontodigital.Company
  alias Pontodigital.Reports.{TimesheetData, PdfGenerator}

  def timesheet(conn, %{"month" => month, "year" => year, "employee_id" => employee_id}) do
    user = conn.assigns.current_scope.user
    target_id = String.to_integer(employee_id)
    return_path = path_to(user, target_id)

    if authorized?(user, target_id) do
      employee = Company.get_employee!(target_id)
      template_name = define_file_type(employee)

      month = String.to_integer(month)
      year = String.to_integer(year)
      data = define_payload(employee, month, year)

      case PdfGenerator.generate(template_name, data) do
        {:ok, pdf_binary} ->
          filename = "espelho_ponto_#{employee.full_name}_#{month}_#{year}.pdf"

          send_download(conn, {:binary, pdf_binary},
            filename: filename,
            content_type: "application/pdf"
          )

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Erro ao gerar o relatório. Tente novamente.")
          |> redirect(to: "#{return_path}")
      end
    else
      conn
      |> put_flash(
        :error,
        "Acesso negado. Você não tem permissão para visualizar este documento."
      )
      |> redirect(to: "#{return_path}")
    end
  end

  defp path_to(user, target_id) do
    case user.role do
      :admin -> ~p"/admin/funcionarios/:#{target_id}"
      :employee -> ~p"/workspace/historico"
    end
  end

  defp authorized?(%{role: :admin}, _target_id), do: true

  defp authorized?(%{id: user_id}, target_id) do
    case Pontodigital.Company.get_employee_by_user(user_id) do
      %{id: ^target_id} -> true
      _ -> false
    end
  end

  defp define_file_type(employee) do
    case employee.work_schedule.name do
      "Padrão 8h" -> "timesheet"
      "Estagio Lindalva" -> "intern_timesheet"
      "PETI" -> "peti_timesheet"
      _ -> "timesheet"
    end
  end
  defp define_payload(employee, month, year) do
    case employee.work_schedule.name do
     "Padrão 8h" -> TimesheetData.build(employee, month, year)
    "Estagio Cetep" -> TimesheetData.build(employee, month, year)
    "PETI" -> TimesheetData.build_weekly_payload(employee, month, year)
    _ -> TimesheetData.build(employee, month, year)
    end
  end
end

defmodule PontodigitalWeb.ReportController do
  use PontodigitalWeb, :controller

  alias Pontodigital.Company
  alias Pontodigital.Reports.{TimesheetData, PdfGenerator}

  def timesheet(conn, %{"month" => month, "year" => year, "employee_id" => employee_id}) do
    employee = Company.get_employee!(employee_id)

    month = String.to_integer(month)
    year = String.to_integer(year)
    data = TimesheetData.build(employee, month, year)

    case PdfGenerator.generate("timesheet", data) do
      {:ok, pdf_binary} ->
        filename = "espelho_ponto_#{employee.full_name}_#{month}_#{year}.pdf"

        send_download(conn, {:binary, pdf_binary},
          filename: filename,
          content_type: "application/pdf"
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Erro ao gerar o relatório. Tente novamente.")
        |> redirect(to: ~p"/workspace/historico")
    end
  end
end

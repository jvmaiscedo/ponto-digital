defmodule Pontodigital.Reports.PdfGenerator do
  def generate(template_name, data) do
    template_dir = Application.app_dir(:pontodigital, "priv/templates/reports")
    temp_dir = Path.join(System.tmp_dir!(), "report_#{Ecto.UUID.generate()}")

    try do
      File.cp_r!(template_dir, temp_dir)

      json_dest = Path.join(temp_dir, "data.json")
      pdf_dest = Path.join(temp_dir, "#{template_name}.pdf")

      File.write!(json_dest, Jason.encode!(data))

      case System.cmd("typst", ["compile", "#{template_name}.typ"], cd: temp_dir) do
        {_, 0} ->
          {:ok, File.read!(pdf_dest)}

        {error_msg, _code} ->
          {:error, "Typst compilation failed: #{error_msg}"}
      end
    after
      File.rm_rf(temp_dir)
    end
  end
end

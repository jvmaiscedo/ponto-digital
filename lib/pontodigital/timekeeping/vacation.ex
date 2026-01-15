defmodule Pontodigital.Timekeeping.Vacation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vacations" do
    field :start_date, :date
    field :end_date, :date
    belongs_to :employee, Pontodigital.Company.Employee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vacation, attrs) do
    vacation
    |> cast(attrs, [:start_date, :end_date, :employee_id])
    |> validate_required([:start_date, :end_date, :employee_id])
    |> validate_dates()
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "deve ser posterior ou igual a data de inicio")
    else
      changeset
    end
  end
end

defmodule Pontodigital.Timekeeping.DailyLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_log" do
    field :date, :date
    field :description, :string
    belongs_to :employee, Pontodigital.Company.Employee

    timestamps()
  end

  @doc false
  def changeset(daily_log, attrs) do
    daily_log
    |> cast(attrs, [:date, :description, :employee_id])
    |> validate_required([:date, :description, :employee_id])
    |> unique_constraint([:employee_id, :date])
  end
end

defmodule Pontodigital.Company.WorkSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_schedules" do
    field :name, :string
    field :daily_hours, :integer
    field :work_days, {:array, :integer}
    field :expected_start, :time
    field :expected_end, :time

    has_many :employees, Pontodigital.Company.Employee

    timestamps()
  end

  @doc false
  def changeset(work_schedule, attrs) do
    work_schedule
    |> cast(attrs, [:name, :daily_hours, :work_days, :expected_start, :expected_end])
    |> validate_required([:name, :daily_hours, :work_days])
    |> validate_number(:daily_hours, greater_than: 0, less_than: 24)
  end
end

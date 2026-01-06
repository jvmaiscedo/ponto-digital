defmodule Pontodigital.Timekeeping.ClockIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clock_ins" do
    field :timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:entrada, :ida_almoco, :retorno_almoco, :saida]
    field :origin, Ecto.Enum, values: [:web, :mobile, :manual], default: :web
    field :status, Ecto.Enum, values: [:valid, :ignored], default: :valid
    field :is_edited, :boolean, default: false
    belongs_to :employee, Pontodigital.Company.Employee
    has_many :adjustments, Pontodigital.Timekeeping.ClockInAdjustment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clock_in, attrs) do
    clock_in
    |> cast(attrs, [:timestamp, :type, :origin, :employee_id])
    |> validate_required([:timestamp, :type, :origin, :employee_id])
  end
end

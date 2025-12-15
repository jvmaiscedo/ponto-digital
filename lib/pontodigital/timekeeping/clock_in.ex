defmodule Pontodigital.Timekeeping.ClockIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clock_ins" do
    field :timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:entrada, :ida_almoco, :retorno_almoco, :saida]
    field :origin, Ecto.Enum, values: [:web, :mobile, :manual], default: :web

    belongs_to :employee, Pontodigital.Company.Employee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clock_in, attrs) do
    clock_in
    |> cast(attrs, [:timestamp, :type, :origin, :employee_id])
    |> validate_required([:timestamp, :type, :origin, :employee_id])
  end
end

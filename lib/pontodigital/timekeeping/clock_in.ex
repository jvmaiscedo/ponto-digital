defmodule Pontodigital.Timekeeping.ClockIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clock_ins" do
    field :timestamp, :utc_datetime
    field :type, Ecto.Enum, values: [:entry, :lunch_out, :lunch_back, :exit]
    field :origin, Ecto.Enum, values: [:web, :mobile, :manual], default: :web
    belongs_to :user, Pontodigital.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(clock_in, attrs) do
    clock_in
    |> cast(attrs, [:timestamp, :type, :origin, :user_id])
    |> validate_required([:timestamp, :type, :origin, :user_id])
  end
end

defmodule Pontodigital.Timekeeping.ClockInAdjustment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "clock_in_adjustments" do
    field :justification, :string
    field :observation, :string
    field :previous_timestamp, :utc_datetime

    field :previous_type, Ecto.Enum, values: [:entrada, :ida_almoco, :retorno_almoco, :saida]

    belongs_to :clock_in, Pontodigital.Timekeeping.ClockIn

    belongs_to :admin_user, Pontodigital.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(adjustment, attrs) do
    adjustment
    |> cast(attrs, [
      :justification,
      :observation,
      :previous_timestamp,
      :previous_type,
      :clock_in_id,
      :admin_user_id
    ])
    |> validate_required([:justification, :clock_in_id, :admin_user_id])
  end
end

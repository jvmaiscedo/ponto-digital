defmodule Pontodigital.Timekeeping.Holiday do
  use Ecto.Schema
  import Ecto.Changeset

  schema "holidays" do
    field :date, :date
    field :name, :string

    timestamps()
  end

  def changeset(holiday, attrs) do
    holiday
    |> cast(attrs, [:date, :name])
    |> validate_required([:date, :name])
    |> unique_constraint(:date, message: "Ja existe um feriado nesta data.")
  end
end

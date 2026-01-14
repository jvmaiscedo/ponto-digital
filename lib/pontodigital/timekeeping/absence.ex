defmodule Pontodigital.Timekeeping.Absence do
  use Ecto.Schema
  import Ecto.Changeset

  schema "absences" do
    field :date, :date
    field :reason, :string
    field :observation, :string

    belongs_to :employee, Pontodigital.Company.Employee
    belongs_to :admin_user, Pontodigital.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(absence, attrs) do
    absence
    |> cast(attrs, [:date, :reason, :observation, :employee_id, :admin_user_id])
    |> validate_required([:date, :reason, :employee_id, :admin_user_id])
    |> unique_constraint([:employee_id, :date], message: "Ja existe abono para essa data.")
  end
end

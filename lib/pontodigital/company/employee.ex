defmodule Pontodigital.Company.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "employees" do
    field :full_name, :string
    field :position, :string
    field :admission_date, :date

    belongs_to :user, Pontodigital.Accounts.User
    has_many :clock_ins, Pontodigital.Timekeeping.ClockIn

    timestamps()
  end

  @doc false
 def changeset(employee, attrs) do
    employee
    |> cast(attrs, [:full_name, :position, :admission_date, :user_id])
    |> validate_required([:full_name, :user_id])
  end
end

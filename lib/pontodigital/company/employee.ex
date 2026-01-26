defmodule Pontodigital.Company.Employee do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:full_name, :email, :position, :role, :status],
    sortable: [:full_name, :email, :inserted_at, :role, :status]
  }

  schema "employees" do
    field :full_name, :string
    field :position, :string
    field :admission_date, :date

    belongs_to :user, Pontodigital.Accounts.User
    belongs_to :work_schedule, Pontodigital.Company.WorkSchedule
    has_many :clock_ins, Pontodigital.Timekeeping.ClockIn

    field :email, :string, virtual: true
    field :password, :string, virtual: true
    field :role, Ecto.Enum, values: [:employee, :admin], virtual: true, default: :employee
    field :status, Ecto.Enum, values: [:working, :offline], virtual: true, default: :offline

    timestamps()
  end

  @doc false
  def changeset(employee, attrs) do
    employee
    |> cast(attrs, [
      :full_name,
      :position,
      :admission_date,
      :user_id,
      :email,
      :password,
      :role,
      :work_schedule_id
    ])
    |> validate_required([:full_name, :position, :admission_date, :email, :password, :role])
    |> foreign_key_constraint(:work_schedule_id)
  end

  def admin_update_changeset(employee, attrs) do
    employee
    |> cast(attrs, [:full_name, :position, :admission_date, :work_schedule_id])
    |> validate_required([:full_name, :position])

    # Sem validação de senha ou email aqui!
  end
end

defmodule Pontodigital.Company.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :name, :string
    belongs_to :manager, Pontodigital.Company.Employee, foreign_key: :manager_id
    has_many :employees, Pontodigital.Company.Employee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :manager_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> foreign_key_constraint(:manager_id)
  end
end

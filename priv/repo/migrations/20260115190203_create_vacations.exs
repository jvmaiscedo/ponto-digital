defmodule Pontodigital.Repo.Migrations.CreateVacations do
  use Ecto.Migration

  def change do
    create table(:vacations) do
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :employee_id, references(:employees, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:vacations, [:employee_id])
    create constraint(:vacations, :end_date_after_start_date, check: "end_date >= start_date")
  end
end

defmodule Pontodigital.Repo.Migrations.CreateDailyLogs do
  use Ecto.Migration

  def change do
    create table(:daily_logs) do
      add :date, :date, null: false
      add :description, :text, null: false
      add :employee_id, references(:employees, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:daily_logs, [:employee_id, :date])
  end
end

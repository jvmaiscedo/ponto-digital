defmodule Pontodigital.Repo.Migrations.CreateWorkSchedules do
  use Ecto.Migration

  def change do
    create table(:work_schedules) do
      add :name, :string, null: false
      add :daily_hours, :integer, null: false
      add :work_days, {:array, :integer}

      add :expected_start, :time
      add :expected_end, :time

      timestamps()
    end

    alter table(:employees) do
      add :work_schedule_id, references(:work_schedules, on_delete: :nilify_all)
    end

    create index(:employees, [:work_schedule_id])
  end
end

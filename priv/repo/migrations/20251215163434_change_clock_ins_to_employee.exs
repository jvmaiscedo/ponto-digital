defmodule Pontodigital.Repo.Migrations.ChangeClockInsToEmployee do
  use Ecto.Migration

  def change do
    alter table(:clock_ins) do
      remove :user_id
      add :employee_id, references(:employees, on_delete: :nothing), null: false
    end

    create index(:clock_ins, [:employee_id])
  end
end

defmodule Pontodigital.Repo.Migrations.CreateClockIns do
  use Ecto.Migration

  def change do
    create table(:clock_ins) do
      add :timestamp, :utc_datetime, null: false
      add :type, :string, null: false
      add :origin, :string, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:clock_ins, [:user_id])
  end
end

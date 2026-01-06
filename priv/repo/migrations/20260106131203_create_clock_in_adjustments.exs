defmodule Pontodigital.Repo.Migrations.CreateClockInAdjustments do
  use Ecto.Migration

  def change do
    create table(:clock_in_adjustments) do
      add :justification, :string
      add :observation, :text

      add :previous_timestamp, :utc_datetime
      add :previous_type, :string

      add :clock_in_id, references(:clock_ins, on_delete: :nothing), null: false

      add :admin_user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:clock_in_adjustments, [:clock_in_id])
    create index(:clock_in_adjustments, [:admin_user_id])
  end
end

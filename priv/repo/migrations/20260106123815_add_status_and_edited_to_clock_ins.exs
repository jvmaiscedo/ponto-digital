defmodule Pontodigital.Repo.Migrations.AddStatusAndEditedToClockIns do
  use Ecto.Migration

  def change do
    alter table(:clock_ins) do
      add :status, :string, default: "valid", null: false

      add :is_edited, :boolean, default: false, null: false
    end
  end
end

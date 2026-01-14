defmodule Pontodigital.Repo.Migrations.CreateHolidaysTable do
  use Ecto.Migration

  def change do
    create table(:holidays) do
      add :date, :date, null: false
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:holidays, [:date])
  end
end

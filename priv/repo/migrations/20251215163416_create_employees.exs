defmodule Pontodigital.Repo.Migrations.CreateEmployees do
  use Ecto.Migration

  def change do
    create table(:employees) do
      add :full_name, :string
      add :position, :string
      add :admission_date, :date
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end


    create unique_index(:employees, [:user_id])
  end
end

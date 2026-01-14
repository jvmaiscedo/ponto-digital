defmodule Pontodigital.Repo.Migrations.CreateAbsencesTable do
  use Ecto.Migration

  def change do
    create table(:absences) do
      add :date, :date, null: false
      add :reason, :string, null: false
      add :observation, :text

      # relacionamentos
      add :employee_id, references(:employees, on_delete: :delete_all), null: false
      add :admin_user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create unique_index(:absences, [:employee_id, :date])
  end
end

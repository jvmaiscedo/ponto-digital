defmodule Pontodigital.Repo.Migrations.AddManagerToDepartments do
  use Ecto.Migration

  def change do
    alter table(:departments) do
      add :manager_id, references(:employees, on_delete: :nilify_all)
    end
  end
end

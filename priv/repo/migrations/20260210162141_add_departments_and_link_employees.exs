defmodule Pontodigital.Repo.Migrations.AddDepartmentsAndLinkEmployees do
  use Ecto.Migration

  def up do
    create table(:departments) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    execute "INSERT INTO departments (name, inserted_at, updated_at) VALUES ('Geral', NOW(), NOW())"
    alter table(:employees) do
      add :department_id, references(:departments, on_delete: :restrict)
    end

    execute "UPDATE employees SET department_id = (SELECT id FROM departments WHERE name = 'Geral' LIMIT 1)"

  alter table(:employees) do
    modify :department_id, :bigint, null: false
  end


  create index(:employees, [:department_id])
end

  def down do
    alter table(:employees) do
      remove :department_id
    end
    drop table(:departments)
  end
end

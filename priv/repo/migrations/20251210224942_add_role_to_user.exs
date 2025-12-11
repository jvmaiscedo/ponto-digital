defmodule Pontodigital.Repo.Migrations.AddRoleToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "employee", null: false
    end
  end
end

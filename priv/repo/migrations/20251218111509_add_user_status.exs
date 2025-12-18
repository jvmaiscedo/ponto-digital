defmodule Pontodigital.Repo.Migrations.AddUserStatus do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :status, :boolean, default: true
    end
  end
end

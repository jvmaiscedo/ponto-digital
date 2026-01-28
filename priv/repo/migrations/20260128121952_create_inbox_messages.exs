defmodule Pontodigital.Repo.Migrations.CreateInboxMessages do
  use Ecto.Migration

  def change do
    create table(:inbox_messages) do
      add :content, :text, null: false
      add :context_date, :date, null: false
      add :category, :string, null: false
      add :attachment_path, :string, null: true
      add :read_at, :utc_datetime, null: true

      add :employee_id, references(:employees, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:inbox_messages, [:employee_id])
    create index(:inbox_messages, [:read_at])
  end
end

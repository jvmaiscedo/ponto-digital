defmodule Pontodigital.Communication.InboxMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inbox_messages" do
    field :content, :string
    field :context_date, :date
    field :attachment_path, :string
    field :read_at, :utc_datetime

    field :category, Ecto.Enum,
      values: [
        :esquecimento,
        :problema_tecnico,
        :atestado_medico,
        :hora_extra_autorizada,
        :outros
      ]

    belongs_to :employee, Pontodigital.Company.Employee

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(inbox_message, attrs) do
    inbox_message
    |> cast(attrs, [:content, :context_date, :category, :attachment_path, :read_at, :employee_id])
    |> validate_required([:content, :context_date, :category, :employee_id])
  end
end

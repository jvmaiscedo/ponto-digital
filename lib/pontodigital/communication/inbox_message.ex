defmodule Pontodigital.Communication.InboxMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Flop.Schema,
    filterable: [:category, :read_at, :content, :context_date],
    sortable: [:inserted_at, :context_date, :category, :read_at],
    default_limit: 10,
    default_order: %{order_by: [:inserted_at], order_directions: [:desc]}
}
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

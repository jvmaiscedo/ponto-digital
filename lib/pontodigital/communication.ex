defmodule Pontodigital.Communication do
  import Ecto.Query, warn: false
  alias Pontodigital.Repo

  alias Pontodigital.Communication.InboxMessage

  @moduledoc """
  Contexto de Comunicação interna (Mensageria).

  Gerencia o envio e leitura de `InboxMessages`. Implementa filtros de visibilidade baseados na hierarquia da empresa.
  """

  @doc """
  Lista mensagens com filtragem dinâmica baseada no papel (`role`) do usuário atual.

  ## Regras de Visibilidade
  - **Master:** Visualiza todas as mensagens do sistema.
  - **Admin (Gestor):** Visualiza apenas as mensagens enviadas por funcionários do **seu departamento** (`department.manager_id == current_user.id`).
  - **Outros:** Retorna uma lista vazia (query com `is_nil(id)`), impedindo acesso a dados não autorizados.

  ## Parâmetros
  - `params`: Parâmetros de paginação e filtro do `Flop`.
  - `current_employee`: O funcionário logado que está requisitando os dados.
  """
  def list_inbox_messages(params \\ %{}, current_employee) do
    current_employee = Pontodigital.Repo.preload(current_employee, :user)

    base_query =
      InboxMessage
      |> preload(employee: :department)

    query =
      cond do
        current_employee.user.role == :master ->
          base_query

        current_employee.user.role == :admin ->
          base_query
          |> join(:inner, [m], e in assoc(m, :employee))
          |> join(:inner, [m, e], d in assoc(e, :department))
          |> where([m, e, d], d.manager_id == ^current_employee.id)

        true ->
          base_query |> where([m], is_nil(m.id))
      end

    Flop.validate_and_run(query, params, for: InboxMessage)
  end

  @doc """
  Gets a single inbox_message.
  Raises Ecto.NoResultsError if the Inbox message does not exist.
  """
  def get_inbox_message!(id) do
    InboxMessage
    |> Repo.get!(id)
    |> Repo.preload(:employee)
  end

  @doc """
  Creates a inbox_message
  """
  def create_inbox_message(attrs \\ %{}) do
    %InboxMessage{}
    |> InboxMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a inbox_message
  """
  def update_inbox_message(%InboxMessage{} = inbox_message, attrs) do
    inbox_message
    |> InboxMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a inbox_message
  """
  def delete_inbox_message(%InboxMessage{} = inbox_message) do
    Repo.delete(inbox_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inbox_message changes
  """
  def change_inbox_message(%InboxMessage{} = inbox_message, attrs \\ %{}) do
    InboxMessage.changeset(inbox_message, attrs)
  end

  @doc """
  Returns a list of unread messages
  """
  def list_unread_messages do
    from(m in InboxMessage,
      where: is_nil(m.read_at),
      preload: [:employee],
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  def mark_as_read(%InboxMessage{} = message) do
    now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    message
    |> Ecto.Changeset.change(read_at: now)
    |> Repo.update()
  end
end

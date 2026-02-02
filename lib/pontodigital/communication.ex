defmodule Pontodigital.Communication do
  import Ecto.Query, warn: false
  alias Pontodigital.Repo

  alias Pontodigital.Communication.InboxMessage

  @doc """
  Returns the list of inbox_messsages.
  """
  def list_inbox_messages do
    InboxMessage
    |> Repo.all()
    |> Repo.preload(:employee)
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
  Returns an '%Ecto.Changeset{}` for tracking inbox_message changes
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

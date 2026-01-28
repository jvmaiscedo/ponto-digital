defmodule Pontodigital.CommunicationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pontodigital.Communication` context.
  """

  @doc """
  Generate a inbox_message.
  """
  def inbox_message_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        attachment_path: "some attachment_path",
        category: "some category",
        content: "some content",
        context_date: ~D[2026-01-27],
        read_at: ~U[2026-01-27 12:19:00Z]
      })

    {:ok, inbox_message} = Pontodigital.Communication.create_inbox_message(scope, attrs)
    inbox_message
  end
end

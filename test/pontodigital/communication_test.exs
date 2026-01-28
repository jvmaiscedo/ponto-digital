defmodule Pontodigital.CommunicationTest do
  use Pontodigital.DataCase

  alias Pontodigital.Communication

  describe "inbox_messages" do
    alias Pontodigital.Communication.InboxMessage

    import Pontodigital.AccountsFixtures, only: [user_scope_fixture: 0]
    import Pontodigital.CommunicationFixtures

    @invalid_attrs %{category: nil, content: nil, context_date: nil, attachment_path: nil, read_at: nil}

    test "list_inbox_messages/1 returns all scoped inbox_messages" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      other_inbox_message = inbox_message_fixture(other_scope)
      assert Communication.list_inbox_messages(scope) == [inbox_message]
      assert Communication.list_inbox_messages(other_scope) == [other_inbox_message]
    end

    test "get_inbox_message!/2 returns the inbox_message with given id" do
      scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      other_scope = user_scope_fixture()
      assert Communication.get_inbox_message!(scope, inbox_message.id) == inbox_message
      assert_raise Ecto.NoResultsError, fn -> Communication.get_inbox_message!(other_scope, inbox_message.id) end
    end

    test "create_inbox_message/2 with valid data creates a inbox_message" do
      valid_attrs = %{category: "some category", content: "some content", context_date: ~D[2026-01-27], attachment_path: "some attachment_path", read_at: ~U[2026-01-27 12:19:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %InboxMessage{} = inbox_message} = Communication.create_inbox_message(scope, valid_attrs)
      assert inbox_message.category == "some category"
      assert inbox_message.content == "some content"
      assert inbox_message.context_date == ~D[2026-01-27]
      assert inbox_message.attachment_path == "some attachment_path"
      assert inbox_message.read_at == ~U[2026-01-27 12:19:00Z]
      assert inbox_message.user_id == scope.user.id
    end

    test "create_inbox_message/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Communication.create_inbox_message(scope, @invalid_attrs)
    end

    test "update_inbox_message/3 with valid data updates the inbox_message" do
      scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      update_attrs = %{category: "some updated category", content: "some updated content", context_date: ~D[2026-01-28], attachment_path: "some updated attachment_path", read_at: ~U[2026-01-28 12:19:00Z]}

      assert {:ok, %InboxMessage{} = inbox_message} = Communication.update_inbox_message(scope, inbox_message, update_attrs)
      assert inbox_message.category == "some updated category"
      assert inbox_message.content == "some updated content"
      assert inbox_message.context_date == ~D[2026-01-28]
      assert inbox_message.attachment_path == "some updated attachment_path"
      assert inbox_message.read_at == ~U[2026-01-28 12:19:00Z]
    end

    test "update_inbox_message/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)

      assert_raise MatchError, fn ->
        Communication.update_inbox_message(other_scope, inbox_message, %{})
      end
    end

    test "update_inbox_message/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Communication.update_inbox_message(scope, inbox_message, @invalid_attrs)
      assert inbox_message == Communication.get_inbox_message!(scope, inbox_message.id)
    end

    test "delete_inbox_message/2 deletes the inbox_message" do
      scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      assert {:ok, %InboxMessage{}} = Communication.delete_inbox_message(scope, inbox_message)
      assert_raise Ecto.NoResultsError, fn -> Communication.get_inbox_message!(scope, inbox_message.id) end
    end

    test "delete_inbox_message/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      assert_raise MatchError, fn -> Communication.delete_inbox_message(other_scope, inbox_message) end
    end

    test "change_inbox_message/2 returns a inbox_message changeset" do
      scope = user_scope_fixture()
      inbox_message = inbox_message_fixture(scope)
      assert %Ecto.Changeset{} = Communication.change_inbox_message(scope, inbox_message)
    end
  end
end

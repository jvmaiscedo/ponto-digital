defmodule Pontodigital.TimekeepingTest do
  use Pontodigital.DataCase

  alias Pontodigital.Timekeeping

  describe "clock_ins" do
    alias Pontodigital.Timekeeping.ClockIn

    import Pontodigital.TimekeepingFixtures

    @invalid_attrs %{timestamp: nil, type: nil, origin: nil}

    test "list_clock_ins/0 returns all clock_ins" do
      clock_in = clock_in_fixture()
      assert Timekeeping.list_clock_ins() == [clock_in]
    end

    test "get_clock_in!/1 returns the clock_in with given id" do
      clock_in = clock_in_fixture()
      assert Timekeeping.get_clock_in!(clock_in.id) == clock_in
    end

    test "create_clock_in/1 with valid data creates a clock_in" do
      valid_attrs = %{timestamp: ~U[2025-12-10 16:50:00Z], type: "some type", origin: "some origin"}

      assert {:ok, %ClockIn{} = clock_in} = Timekeeping.create_clock_in(valid_attrs)
      assert clock_in.timestamp == ~U[2025-12-10 16:50:00Z]
      assert clock_in.type == "some type"
      assert clock_in.origin == "some origin"
    end

    test "create_clock_in/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timekeeping.create_clock_in(@invalid_attrs)
    end

    test "update_clock_in/2 with valid data updates the clock_in" do
      clock_in = clock_in_fixture()
      update_attrs = %{timestamp: ~U[2025-12-11 16:50:00Z], type: "some updated type", origin: "some updated origin"}

      assert {:ok, %ClockIn{} = clock_in} = Timekeeping.update_clock_in(clock_in, update_attrs)
      assert clock_in.timestamp == ~U[2025-12-11 16:50:00Z]
      assert clock_in.type == "some updated type"
      assert clock_in.origin == "some updated origin"
    end

    test "update_clock_in/2 with invalid data returns error changeset" do
      clock_in = clock_in_fixture()
      assert {:error, %Ecto.Changeset{}} = Timekeeping.update_clock_in(clock_in, @invalid_attrs)
      assert clock_in == Timekeeping.get_clock_in!(clock_in.id)
    end

    test "delete_clock_in/1 deletes the clock_in" do
      clock_in = clock_in_fixture()
      assert {:ok, %ClockIn{}} = Timekeeping.delete_clock_in(clock_in)
      assert_raise Ecto.NoResultsError, fn -> Timekeeping.get_clock_in!(clock_in.id) end
    end

    test "change_clock_in/1 returns a clock_in changeset" do
      clock_in = clock_in_fixture()
      assert %Ecto.Changeset{} = Timekeeping.change_clock_in(clock_in)
    end
  end
end

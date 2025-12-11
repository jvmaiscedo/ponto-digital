defmodule Pontodigital.TimekeepingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pontodigital.Timekeeping` context.
  """

  @doc """
  Generate a clock_in.
  """
  def clock_in_fixture(attrs \\ %{}) do
    {:ok, clock_in} =
      attrs
      |> Enum.into(%{
        origin: "some origin",
        timestamp: ~U[2025-12-10 16:50:00Z],
        type: "some type"
      })
      |> Pontodigital.Timekeeping.create_clock_in()

    clock_in
  end
end

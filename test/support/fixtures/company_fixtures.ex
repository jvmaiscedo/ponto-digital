defmodule Pontodigital.CompanyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pontodigital.Company` context.
  """

  @doc """
  Generate a employee.
  """
  def employee_fixture(attrs \\ %{}) do
    {:ok, employee} =
      attrs
      |> Enum.into(%{
        admission_date: ~D[2025-12-14],
        flag: "some flag",
        full_name: "some full_name",
        position: "some position"
      })
      |> Pontodigital.Company.create_employee()

    employee
  end
end

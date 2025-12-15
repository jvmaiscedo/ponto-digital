defmodule Pontodigital.CompanyTest do
  use Pontodigital.DataCase

  alias Pontodigital.Company

  describe "employees" do
    alias Pontodigital.Company.Employee

    import Pontodigital.CompanyFixtures

    @invalid_attrs %{position: nil, flag: nil, full_name: nil, admission_date: nil}

    test "list_employees/0 returns all employees" do
      employee = employee_fixture()
      assert Company.list_employees() == [employee]
    end

    test "get_employee!/1 returns the employee with given id" do
      employee = employee_fixture()
      assert Company.get_employee!(employee.id) == employee
    end

    test "create_employee/1 with valid data creates a employee" do
      valid_attrs = %{position: "some position", flag: "some flag", full_name: "some full_name", admission_date: ~D[2025-12-14]}

      assert {:ok, %Employee{} = employee} = Company.create_employee(valid_attrs)
      assert employee.position == "some position"
      assert employee.flag == "some flag"
      assert employee.full_name == "some full_name"
      assert employee.admission_date == ~D[2025-12-14]
    end

    test "create_employee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Company.create_employee(@invalid_attrs)
    end

    test "update_employee/2 with valid data updates the employee" do
      employee = employee_fixture()
      update_attrs = %{position: "some updated position", flag: "some updated flag", full_name: "some updated full_name", admission_date: ~D[2025-12-15]}

      assert {:ok, %Employee{} = employee} = Company.update_employee(employee, update_attrs)
      assert employee.position == "some updated position"
      assert employee.flag == "some updated flag"
      assert employee.full_name == "some updated full_name"
      assert employee.admission_date == ~D[2025-12-15]
    end

    test "update_employee/2 with invalid data returns error changeset" do
      employee = employee_fixture()
      assert {:error, %Ecto.Changeset{}} = Company.update_employee(employee, @invalid_attrs)
      assert employee == Company.get_employee!(employee.id)
    end

    test "delete_employee/1 deletes the employee" do
      employee = employee_fixture()
      assert {:ok, %Employee{}} = Company.delete_employee(employee)
      assert_raise Ecto.NoResultsError, fn -> Company.get_employee!(employee.id) end
    end

    test "change_employee/1 returns a employee changeset" do
      employee = employee_fixture()
      assert %Ecto.Changeset{} = Company.change_employee(employee)
    end
  end
end

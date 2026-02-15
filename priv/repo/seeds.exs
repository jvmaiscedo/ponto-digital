# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Pontodigital.Repo.insert!(%Pontodigital.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Pontodigital.Company.WorkSchedule
alias Pontodigital.Company.Department
alias Pontodigital.Repo

upsert_department = fn name ->
  case Repo.get_by(Department, name: name) do
    nil ->
      Repo.insert!(%Department{name: name})
      |> tap(fn _ -> IO.puts("🏢 Departamento criado: #{name}") end)

    dep ->
      dep
  end
end

geral_dep = upsert_department.("Geral")
upsert_department.("Laboratório Lindalva")
upsert_department.("Laboratório LARA")
upsert_department.("CIPEC")

unless Pontodigital.Accounts.get_user_by_email("admin@admin.com") do
  {:ok, admin_user} =
    Pontodigital.Accounts.register_user(%{
      email: "admin@admin.com",
      password: "computacao321",
      role: :master
    })

  Pontodigital.Accounts.User.confirm_changeset(admin_user)
  |> Pontodigital.Repo.update()

  Pontodigital.Company.create_employee(%{
    full_name: "Admin Master",
    position: "Gestor",
    admission_date: Date.utc_today(),
    user_id: admin_user.id,
    department_id: geral_dep.id
  })

  IO.puts("✅ Usuário Admin criado com sucesso e vinculado ao departamento 'Geral'!")
else
  IO.puts("⚠️  Usuário Admin já existe.")
end

upsert_schedule = fn attrs ->
  case Repo.get_by(WorkSchedule, name: attrs.name) do
    nil ->
      %WorkSchedule{}
      |> WorkSchedule.changeset(attrs)
      |> Repo.insert!()

      IO.puts("⏰ Jornada criada: #{attrs.name}")

    _schedule ->
      IO.puts("ℹ️  Jornada já existe: #{attrs.name}")
  end
end

upsert_schedule.(%{
  name: "Estagio Lindalva",
  daily_hours: 4,
  work_days: [1, 2, 3, 4, 5],
  expected_start: nil,
  expected_end: nil
})

upsert_schedule.(%{
  name: "Estagio Cetep",
  daily_hours: 4,
  work_days: [1, 2, 3, 4, 5],
  expected_start: nil,
  expected_end: nil
})

upsert_schedule.(%{
  name: "PETI",
  daily_hours: 4,
  work_days: [1, 2, 3, 4, 5],
  expected_start: nil,
  expected_end: nil
})

upsert_schedule.(%{
  name: "Padrão 8h",
  daily_hours: 8,
  work_days: [1, 2, 3, 4, 5],
  expected_start: nil,
  expected_end: nil
})

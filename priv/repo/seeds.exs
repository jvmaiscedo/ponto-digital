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
# priv/repo/seeds.exs
alias Pontodigital.Company.WorkSchedule
alias Pontodigital.Repo
# Verifica se o admin já existe para não dar erro ao rodar duas vezes
unless Pontodigital.Accounts.get_user_by_email("admin@admin.com") do
  {:ok, admin_user} =
    Pontodigital.Accounts.register_user(%{
      email: "admin@admin.com",
      password: "computacao321",
      role: :admin
    })

  # Confirma o email automaticamente
  Pontodigital.Accounts.User.confirm_changeset(admin_user)
  |> Pontodigital.Repo.update()

  # Cria o vínculo de funcionário
  Pontodigital.Company.create_employee(%{
    full_name: "Admin Master",
    position: "Gestor",
    admission_date: Date.utc_today(),
    user_id: admin_user.id
  })

  IO.puts("✅ Usuário Admin criado com sucesso!")
else
  IO.puts("⚠️  Usuário Admin já existe.")
end

upsert_schedule = fn attrs ->
  case Repo.get_by(WorkSchedule, name: attrs.name) do
    nil ->
      %WorkSchedule{}
      |> WorkSchedule.changeset(attrs)
      |> Repo.insert!()

      IO.puts("Criado: #{attrs.name}")

    _schedule ->
      IO.puts("Já existe: #{attrs.name}")
  end
end

upsert_schedule.(%{
  name: "Estagio Lindalva",
  daily_hours: 4,
  # Segunda a Sexta
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

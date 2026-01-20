defmodule PontodigitalWeb.EmployeeLive.Hooks.AssignEmployee do
  import Phoenix.Component
  alias Pontodigital.{Company, Repo}

  def on_mount(:default, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    employee =
      Company.get_employee_by_user!(user.id)
      |> Repo.preload(:work_schedule)

    {:cont, assign(socket, :employee, employee)}
  end
end

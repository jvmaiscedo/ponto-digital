defmodule PontodigitalWeb.EmployeeLive.Hooks.AssignEmployee do
  import Phoenix.Component
  alias Pontodigital.Company

  def on_mount(:default, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    employee = Company.get_employee_by_user!(user.id)

    {:cont, assign(socket, :employee, employee)}
  end
end

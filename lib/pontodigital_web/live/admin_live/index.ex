defmodule PontodigitalWeb.AdminLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Company
  alias Pontodigital.Repo

  @impl true
  def mount(_params, _session, socket) do
    current_user = Repo.preload(socket.assigns.current_scope.user, :employee)
    total_funcionarios = Company.count_employees()

    primeiro_nome = extrair_primeiro_nome(current_user)

    {:ok,
     socket
     |> assign(total_funcionarios: total_funcionarios)
     |> assign(current_user: current_user)
     |> assign(primeiro_nome: primeiro_nome)}
  end

  defp extrair_primeiro_nome(%{employee: %Pontodigital.Company.Employee{full_name: nome}}) when not is_nil(nome) do
    nome
    |> String.split(" ")
    |> List.first()
  end

  defp extrair_primeiro_nome(%{email: email}) do
    email
    |> String.split("@")
    |> List.first()
    |> String.split(".")
    |> List.first()
    |> String.capitalize()
  end
end

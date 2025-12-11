defmodule PontodigitalWeb.UserLive.Registration do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Accounts
  alias Pontodigital.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Crie sua conta
            <:subtitle>
              Já tem conta?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Entrar
              </.link>
            </:subtitle>
          </.header>
        </div>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input field={@form[:email]} type="email" label="Email" required />

          <.input field={@form[:password]} type="password" label="Senha" required />

          <.input
            field={@form[:role]}
            type="select"
            label="Cargo"
            options={[Funcionário: "employee", Admin: "admin"]}
          />

          <.button phx-disable-with="Criando..." class="btn btn-primary w-full mt-4">
            Criar conta
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: PontodigitalWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    # Mudança aqui: Usar change_user_registration para preparar o changeset completo
    changeset = Accounts.change_user_registration(%User{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    # Mudança aqui: Validar todos os campos (email, senha, role)
    changeset = Accounts.change_user_registration(%User{}, user_params)

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end

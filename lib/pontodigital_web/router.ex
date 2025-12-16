defmodule PontodigitalWeb.Router do
  # 1. REMOVI O ALIAS DAQUI POIS GERA CONFLITO COM O SCOPE
  use PontodigitalWeb, :router

  import PontodigitalWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PontodigitalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :employee_access do
    plug :browser
    plug :require_authenticated_user
    plug :require_employee
  end

  pipeline :admin_access do
    plug :browser
    plug :require_authenticated_user
    plug :require_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PontodigitalWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pontodigital, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PontodigitalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/admin", PontodigitalWeb do
    pipe_through :admin_access

    live_session :admin_dashboard,
      on_mount: [{PontodigitalWeb.UserAuth, :mount_current_scope}] do
      live "/dashboard", AdminLive.Dashboard, :index
      live "/funcionarios/novo", AdminLive.EmployeeManagement.New, :new
    end
  end

  scope "/workspace", PontodigitalWeb do
    pipe_through :employee_access

    live_session :employee_workspace,
      on_mount: [{PontodigitalWeb.UserAuth, :require_authenticated}] do
      live "/ponto", ClockInLive.Index, :index
    end
  end

  ## --- ÁREA DO USUÁRIO COMUM (Configs) ---
  scope "/", PontodigitalWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PontodigitalWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", PontodigitalWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{PontodigitalWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end

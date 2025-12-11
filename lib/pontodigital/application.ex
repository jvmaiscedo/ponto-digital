defmodule Pontodigital.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PontodigitalWeb.Telemetry,
      Pontodigital.Repo,
      {DNSCluster, query: Application.get_env(:pontodigital, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Pontodigital.PubSub},
      # Start a worker by calling: Pontodigital.Worker.start_link(arg)
      # {Pontodigital.Worker, arg},
      # Start to serve requests, typically the last entry
      PontodigitalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pontodigital.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PontodigitalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

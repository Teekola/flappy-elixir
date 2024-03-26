defmodule FlappyElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FlappyElixirWeb.Telemetry,
      FlappyElixir.Repo,
      {DNSCluster, query: Application.get_env(:flappy_elixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FlappyElixir.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: FlappyElixir.Finch},
      # Start a worker by calling: FlappyElixir.Worker.start_link(arg)
      # {FlappyElixir.Worker, arg},
      # Start to serve requests, typically the last entry
      FlappyElixirWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FlappyElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlappyElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

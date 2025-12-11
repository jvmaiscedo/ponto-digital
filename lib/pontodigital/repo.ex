defmodule Pontodigital.Repo do
  use Ecto.Repo,
    otp_app: :pontodigital,
    adapter: Ecto.Adapters.Postgres
end

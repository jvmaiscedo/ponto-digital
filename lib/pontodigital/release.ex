defmodule Pontodigital.Release do
  @app :pontodigital

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &eval_seed/1)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp eval_seed(_repo) do
    # Encontra o arquivo seeds.exs dentro da pasta priv do release compilado
    seeds_path = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

    if File.exists?(seeds_path) do
      Code.eval_file(seeds_path)
    end
  end
end

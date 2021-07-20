defmodule PhxDiff.Diffs.AppRepo do
  @moduledoc false

  alias PhxDiff.Diffs

  alias PhxDiff.Diffs.{
    AppRepo.AppGenerator,
    AppSpecification,
    Config
  }

  @type version :: PhxDiff.Diffs.version()

  @spec all_versions(Config.t()) :: [version]
  def all_versions(%Config{} = config) do
    config
    |> app_specifications_for_pre_generated_apps()
    |> MapSet.new(& &1.phoenix_version)
    |> MapSet.to_list()
    |> Enum.sort_by(&Version.parse!/1, &(Version.compare(&1, &2) == :lt))
  end

  @spec release_versions(Config.t()) :: [version]
  def release_versions(%Config{} = config),
    do: config |> all_versions() |> Enum.reject(&pre_release?/1)

  defp pre_release?(version), do: !Enum.empty?(Version.parse!(version).pre)

  @spec latest_version(Config.t()) :: version
  def latest_version(%Config{} = config),
    do: config |> all_versions() |> List.last()

  @spec previous_release_version(Config.t()) :: version
  def previous_release_version(%Config{} = config) do
    releases = release_versions(config)
    latest_release = releases |> List.last()

    if latest_version(config) == latest_release do
      releases |> Enum.at(-2)
    else
      latest_release
    end
  end

  @spec fetch_app_path(Config.t(), AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :invalid_version}
  def fetch_app_path(%Config{} = config, %AppSpecification{} = app_specification) do
    if app_generated_for_specification?(config, app_specification) do
      {:ok, app_path(config, app_specification)}
    else
      {:error, :invalid_version}
    end
  end

  @spec generate_sample_app(Config.t(), AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  def generate_sample_app(%Config{} = config, %AppSpecification{} = app_spec) do
    with {:ok, job} <- AppGenerator.generate(config, app_spec),
         {:ok, path_in_storage} <- store_generated_app(config, app_spec, job) do
      {:ok, path_in_storage}
    end
  end

  defp store_generated_app(config, app_spec, job) do
    destination_path = app_path(config, app_spec)

    File.rm_rf(destination_path)
    File.mkdir_p!(destination_path)

    File.rename!(job.project_path, destination_path)
    File.rm_rf(job.base_path)

    {:ok, destination_path}
  end

  defp app_generated_for_specification?(config, app_spec) do
    app_spec in app_specifications_for_pre_generated_apps(config)
  end

  defp app_path(config, app_spec) do
    %Config{app_repo_path: app_repo_path} = config
    %AppSpecification{phoenix_version: version} = app_spec

    Path.join(app_repo_path, version)
  end

  defp app_specifications_for_pre_generated_apps(%Config{app_repo_path: app_repo_path}) do
    case File.ls(app_repo_path) do
      {:ok, files} ->
        Enum.map(files, &Diffs.fetch_default_app_specification!/1)

      {:error, _reason} ->
        []
    end
  end
end

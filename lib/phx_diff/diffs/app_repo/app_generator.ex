defmodule PhxDiff.Diffs.AppRepo.AppGenerator do
  @moduledoc false

  alias PhxDiff.Diffs.AppRepo.AppGenerator.AppGenerationJob
  alias PhxDiff.Diffs.AppRepo.AppGenerator.EarthlyHelpers
  alias PhxDiff.Diffs.AppSpecification
  alias PhxDiff.Diffs.Config

  @type dir :: String.t()

  @type generate_opt :: {:workspace_path, String.t()}

  @spec generate(Config.t(), AppSpecification.t()) ::
          {:ok, AppGenerationJob.t()} | {:error, :unknown_version}
  def generate(%Config{} = config, %AppSpecification{} = app_specification) do
    %Config{app_generator_workspace_path: workspace_path} = config

    generate_sample_app(workspace_path, app_specification)
  end

  defp generate_sample_app(workspace_path, app_specification) do
    app_generation_job =
      [workspace_path, "generated_apps", random_string(16)]
      |> Path.join()
      |> AppGenerationJob.new()

    with :ok <- run_phoenix_generator(app_generation_job, app_specification),
         :ok <- clean_up_generated_app!(app_generation_job) do
      {:ok, app_generation_job}
    end
  end

  defp run_phoenix_generator(app_generation_job, app_specification) do
    set_up_earthly!(app_generation_job.tmp_path, app_specification)

    earthly_run(
      [
        "--build-arg",
        "OUTPUT_PATH=#{Path.expand(app_generation_job.project_path)}",
        "+build-project"
      ],
      app_generation_job.tmp_path
    )
    |> case do
      {_output, 0} ->
        :ok

      {output, 1} ->
        try do
          case EarthlyHelpers.parse_error_output(app_specification, output) do
            :unknown_version ->
              {:error, :unknown_version}

            :unknown_error ->
              raise """
              error occurred while installing phx_new

              #{output}
              """
          end
        after
          File.rm_rf(app_generation_job.base_path)
        end
    end
  end

  defp set_up_earthly!(workspace_path, app_specification) do
    File.mkdir_p!(workspace_path)

    app_specification
    |> EarthlyHelpers.generate_earthfile_contents()
    |> write_file!(Path.join(workspace_path, "Earthfile"))

    :ok
  end

  def earthly_run(args, path, opts \\ [])
      when is_list(args) and is_binary(path) and is_list(opts) do
    System.cmd(
      "earthly",
      args,
      [stderr_to_stdout: true, cd: path] ++ opts
    )
  end

  defp clean_up_generated_app!(app_generation_job) do
    sample_app_path = app_generation_job.project_path

    update_file!(Path.join(sample_app_path, "config/prod.secret.exs"), fn file ->
      String.replace(file, ~r/secret_key_base:.*/, "secret_key_base: \"aaaaaaaa\"")
    end)

    update_file!(Path.join(sample_app_path, "config/config.exs"), fn file ->
      file
      |> String.replace(~r/secret_key_base:.*/, "secret_key_base: \"aaaaaaaa\",")
      |> String.replace(~r/signing_salt:.*/, "signing_salt: \"aaaaaaaa\"]")
    end)

    update_file!(Path.join(sample_app_path, "lib/sample_app_web/endpoint.ex"), fn file ->
      String.replace(file, ~r/signing_salt:.*/, "signing_salt: \"aaaaaaaa\"")
    end)
  end

  defp update_file!(path, function) do
    path
    |> File.read!()
    |> function.()
    |> write_file!(path)
  end

  defp write_file!(contents, path) do
    File.write!(path, contents)
  end

  defp random_string(length) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, length)
  end
end

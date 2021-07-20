defmodule PhxDiff.Diffs.AppRepo.AppGenerator.EarthlyHelpers do
  @moduledoc false

  alias PhxDiff.Diffs.AppSpecification

  @image_tag "1.11.3-erlang-23.2.2-alpine-3.12.1"

  @spec generate_earthfile_contents(AppSpecification.t()) :: String.t()
  def generate_earthfile_contents(%AppSpecification{} = app_specification) do
    case get_earthfile_version(app_specification) do
      :hex_based_install ->
        hex_based_install_earthfile(app_specification)

      :legacy_install ->
        legacy_install_earthfile(app_specification)
    end
  end

  @spec parse_error_output(AppSpecification.t(), String.t()) :: :unknown_version | :unknown_error
  def parse_error_output(%AppSpecification{} = app_specification, output)
      when is_binary(output) do
    app_specification
    |> get_earthfile_version()
    |> case do
      :hex_based_install ->
        hex_based_install_parse_error_output(output)

      :legacy_install ->
        legacy_install_parse_error_output(output)
    end
  end

  defp get_earthfile_version(app_specification) do
    if Version.match?(app_specification.phoenix_version, "~> 1.4") do
      :hex_based_install
    else
      :legacy_install
    end
  end

  defp hex_based_install_earthfile(app_specification) do
    phoenix = app_specification.phoenix_version

    phx_new_arg_string =
      ["--module", "SampleApp", "--app", "sample_app"]
      |> Kernel.++(app_specification.phx_new_arguments)
      |> escape_shell_args()
      |> Enum.join(" ")

    """
    build-project:
      FROM hexpm/elixir:#{@image_tag}

      WORKDIR /build
      RUN mix local.rebar --force
      RUN mix local.hex --force
      RUN mix archive.install hex phx_new #{phoenix} --force

      RUN mix phx.new generated_app #{phx_new_arg_string}

      ARG OUTPUT_PATH=generated_app
      SAVE ARTIFACT ./generated_app AS LOCAL $OUTPUT_PATH
    """
  end

  defp hex_based_install_parse_error_output(output) do
    if String.match?(output, ~r/no matching version/i) do
      :unknown_version
    else
      :unknown_error
    end
  end

  defp legacy_install_earthfile(app_specification) do
    phoenix = app_specification.phoenix_version

    phoenix_archive_url =
      "https://github.com/phoenixframework/archives/raw/master/phx_new-#{phoenix}.ez"

    phx_new_arg_string =
      ["--module", "SampleApp", "--app", "sample_app"]
      |> Kernel.++(app_specification.phx_new_arguments)
      |> escape_shell_args()
      |> Enum.join(" ")

    """
    build-project:
      FROM hexpm/elixir:#{@image_tag}

      WORKDIR /build
      RUN mix local.rebar --force
      RUN mix local.hex --force
      RUN apk add --no-progress --update curl
      RUN curl -Lfs -o phx_new.ez #{phoenix_archive_url} && mix archive.install phx_new.ez --force

      RUN mix phx.new generated_app #{phx_new_arg_string}

      ARG OUTPUT_PATH=generated_app
      SAVE ARTIFACT ./generated_app AS LOCAL $OUTPUT_PATH
    """
  end

  defp legacy_install_parse_error_output(output) do
    if String.match?(output, ~r/failed with exit code 22/i) do
      :unknown_version
    else
      :unknown_error
    end
  end

  # Escaping based on https://stackoverflow.com/a/20053121
  defp escape_shell_args([]), do: []

  defp escape_shell_args([arg | rest]) when is_binary(arg) do
    [
      String.replace(arg, ~r|[^a-zA-Z0-9,._+@%/-]|, fn str -> "\\" <> str end)
      | escape_shell_args(rest)
    ]
  end
end

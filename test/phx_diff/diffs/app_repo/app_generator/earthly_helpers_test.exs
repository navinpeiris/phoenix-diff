defmodule PhxDiff.Diffs.AppRepo.AppGenerator.EarthlyHelpersTest do
  use ExUnit.Case, async: true

  alias PhxDiff.Diffs.AppRepo.AppGenerator.EarthlyHelpers
  alias PhxDiff.Diffs.AppSpecification

  @image_tag "1.11.3-erlang-23.2.2-alpine-3.12.1"

  describe "generate_earthfile_contents/1" do
    test "generates a phx.new based Earthfile" do
      earthfile =
        Version.parse!("1.5.7")
        |> AppSpecification.new(["--live"])
        |> EarthlyHelpers.generate_earthfile_contents()

      assert earthfile == """
             build-project:
               FROM hexpm/elixir:#{@image_tag}

               WORKDIR /build
               RUN mix local.rebar --force
               RUN mix local.hex --force
               RUN mix archive.install hex phx_new 1.5.7 --force

               RUN mix phx.new generated_app --module SampleApp --app sample_app --live

               ARG OUTPUT_PATH=generated_app
               SAVE ARTIFACT ./generated_app AS LOCAL $OUTPUT_PATH
             """
    end

    test "properly escapes args with spaces and single quotes" do
      earthfile =
        Version.parse!("1.4.10")
        |> AppSpecification.new(["arg with spaces", "hacker's args"])
        |> EarthlyHelpers.generate_earthfile_contents()

      assert earthfile =~ """
             RUN mix phx.new generated_app --module SampleApp --app sample_app arg\\ with\\ spaces hacker\\'s\\ args
             """
    end
  end
end

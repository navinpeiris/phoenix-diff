defmodule PhxDiff.DiffsTest do
  use ExUnit.Case

  import PhxDiff.TestSupport.FileHelpers

  alias PhxDiff.Diffs

  alias PhxDiff.Diffs.{
    AppSpecification,
    Config
  }

  describe "all_versions/1" do
    test "returns all versions" do
      versions = Diffs.all_versions()

      assert versions |> length() > 25

      assert versions |> Enum.member?("1.3.0")
      assert versions |> Enum.member?("1.4.0-rc.2")
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.all_versions(config: config)
      end)
    end
  end

  describe "release_versions/1" do
    test "returns all versions" do
      versions = Diffs.release_versions()

      assert versions |> length() > 20

      assert versions |> Enum.member?("1.3.0")
      refute versions |> Enum.member?("1.4.0-rc.2")
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.release_versions(config: config)
      end)
    end
  end

  describe "get_diff/3" do
    test "returns content when versions are valid" do
      source = Diffs.fetch_default_app_specification!("1.3.1")
      target = Diffs.fetch_default_app_specification!("1.3.2")

      {:ok, diff} = Diffs.get_diff(source, target)

      assert diff =~ "config/config.exs config/config.exs"
    end

    test "returns empty when versions are the same" do
      source = Diffs.fetch_default_app_specification!("1.3.1")
      target = Diffs.fetch_default_app_specification!("1.3.1")

      {:ok, diff} = Diffs.get_diff(source, target)

      assert diff == ""
    end

    test "returns an error when an app hasn't been generated for the given version" do
      with_tmp(fn path ->
        config = build_config(path)

        source = Diffs.fetch_default_app_specification!("1.3.1")
        target = Diffs.fetch_default_app_specification!("1.4.2")

        assert {:error, :invalid_versions} = Diffs.get_diff(source, target, config: config)
      end)
    end
  end

  describe "generate_sample_app/2" do
    test "stores the newly generated sample app in config.app_repo_path" do
      with_tmp(fn path ->
        config = build_config(path)

        assert {:ok, storage_dir} =
                 "1.5.3"
                 |> Diffs.fetch_default_app_specification!()
                 |> Diffs.generate_sample_app(config: config)

        assert storage_dir == Path.join(config.app_repo_path, "1.5.3")

        assert_file(Path.join(storage_dir, "mix.exs"))

        assert_file(Path.join(storage_dir, "config/prod.secret.exs"), fn file ->
          assert file =~ ~s|secret_key_base: "aaaaaaaa"|
        end)

        assert_file(Path.join(storage_dir, "config/config.exs"), fn file ->
          assert file =~ ~s|secret_key_base: "aaaaaaaa"|
          assert file =~ ~s|signing_salt: "aaaaaaaa"|
        end)

        assert_file(Path.join(storage_dir, "lib/sample_app_web/endpoint.ex"), fn file ->
          assert file =~ ~s|signing_salt: "aaaaaaaa"|
        end)

        assert ["1.5.3"] = Diffs.all_versions(config: config)

        assert_temp_dirs_cleaned_up(config)
      end)
    end

    test "returns {:error, :unknown_version} when phoenix does not have the given version number" do
      with_tmp(fn path ->
        config = build_config(path)

        assert {:error, :unknown_version} =
                 Diffs.fetch_default_app_specification!("0.1.10")
                 |> Diffs.generate_sample_app(config: config)

        assert_temp_dirs_cleaned_up(config)
      end)
    end
  end

  describe "fetch_default_app_specification!/1" do
    test "returns an app spec with no arguments for versions less than 1.5.0" do
      assert Diffs.fetch_default_app_specification!("1.4.16") ==
               %AppSpecification{
                 phoenix_version: "1.4.16",
                 phx_new_arguments: []
               }
    end

    test "returns an app spec with --live argument for versions >= 1.5.0" do
      for version <- ["1.5.0-rc.0", "1.5.0", "1.5.1"] do
        assert Diffs.fetch_default_app_specification!(version) ==
                 %AppSpecification{
                   phoenix_version: version,
                   phx_new_arguments: ["--live"]
                 }
      end
    end

    test "raises on an invalid version number" do
      assert_raise Version.InvalidVersionError, fn ->
        Diffs.fetch_default_app_specification!("foo")
      end
    end
  end

  describe "fetch_default_app_specification/1" do
    test "returns an app spec with no arguments for versions less than 1.5.0" do
      assert {:ok,
              %AppSpecification{
                phoenix_version: "1.4.16",
                phx_new_arguments: []
              }} = Diffs.fetch_default_app_specification("1.4.16")
    end

    test "returns an app spec with --live argument for versions >= 1.5.0" do
      for version <- ["1.5.0-rc.0", "1.5.0", "1.5.1"] do
        assert {:ok,
                %AppSpecification{
                  phoenix_version: ^version,
                  phx_new_arguments: ["--live"]
                }} = Diffs.fetch_default_app_specification(version)
      end
    end

    test "returns {:error, :invalid_version} on an invalid version number" do
      assert {:error, :invalid_version} = Diffs.fetch_default_app_specification("foo")
    end
  end

  defp build_config(tmp_path) do
    %Config{
      app_repo_path: Path.join(tmp_path, "app_repo"),
      app_generator_workspace_path: Path.join(tmp_path, "generator_workspace")
    }
  end

  defp assert_temp_dirs_cleaned_up(config) do
    mix_archives_tmp_path =
      Path.join([
        config.app_generator_workspace_path,
        "mix_archives",
        "tmp"
      ])

    assert_dir_empty(mix_archives_tmp_path)

    generated_apps_path =
      Path.join([
        config.app_generator_workspace_path,
        "generated_apps"
      ])

    assert_dir_empty(generated_apps_path)
  end

  defp assert_dir_empty(path) do
    case File.ls(path) do
      {:ok, []} ->
        :ok

      {:ok, contents} when is_list(contents) ->
        flunk("""
        expected #{path} to be empty, but had the following entities

        #{inspect(contents)}
        """)

      {:error, _} ->
        :ok
    end
  end
end

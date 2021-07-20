defmodule Mix.Tasks.PhxDiff.Gen.SampleTest do
  use ExUnit.Case

  alias Mix.Tasks.PhxDiff.Gen
  alias PhxDiff.Diffs

  test "the appropriate diff is returned after generating 2 versions of an app" do
    Gen.Sample.run(["1.5.2"])

    assert_receive {:mix_shell, :info, [msg]}

    assert msg == """

           Successfully generated sample app.

           To add this to version control, run:

               git add data/sample-app/1.5.2
               git add -f data/sample-app/1.5.2/config/prod.secret.exs
           """

    Gen.Sample.run(["1.5.3"])

    assert {:ok, diff} =
             Diffs.get_diff(
               Diffs.fetch_default_app_specification!("1.5.2"),
               Diffs.fetch_default_app_specification!("1.5.3")
             )

    assert diff =~
             """
             @@ -33,11 +33,11 @@
                # Type `mix help deps` for examples and options.
                defp deps do
                  [
             -      {:phoenix, "~> 1.5.2"},
             +      {:phoenix, "~> 1.5.3"},
                    {:phoenix_ecto, "~> 4.1"},
                    {:ecto_sql, "~> 3.4"},
                    {:postgrex, ">= 0.0.0"},
             -      {:phoenix_live_view, "~> 0.12.0"},
             +      {:phoenix_live_view, "~> 0.13.0"},
                    {:floki, ">= 0.0.0", only: :test},
                    {:phoenix_html, "~> 2.11"},
                    {:phoenix_live_reload, "~> 1.2", only: :dev},
             """
  end

  test "the appropriate diff is returned when generating phoenix 1.4 apps" do
    Gen.Sample.run(["1.4.16"])

    assert_receive {:mix_shell, :info, [msg]}

    assert msg == """

           Successfully generated sample app.

           To add this to version control, run:

               git add data/sample-app/1.4.16
               git add -f data/sample-app/1.4.16/config/prod.secret.exs
           """

    Gen.Sample.run(["1.4.17"])

    assert {:ok, diff} =
             Diffs.get_diff(
               Diffs.fetch_default_app_specification!("1.4.16"),
               Diffs.fetch_default_app_specification!("1.4.17")
             )

    assert diff =~
             """
             @@ -33,7 +33,7 @@
                # Type `mix help deps` for examples and options.
                defp deps do
                  [
             -      {:phoenix, "~> 1.4.16"},
             +      {:phoenix, "~> 1.4.17"},
                    {:phoenix_pubsub, "~> 1.1"},
                    {:phoenix_ecto, "~> 4.0"},
                    {:ecto_sql, "~> 3.1"},
             """
  end

  test "the appropriate diff is returned when generating phoenix 1.3.x apps" do
    Gen.Sample.run(["1.3.3"])

    Gen.Sample.run(["1.3.4"])

    assert {:ok, diff} =
             Diffs.get_diff(
               Diffs.fetch_default_app_specification!("1.3.3"),
               Diffs.fetch_default_app_specification!("1.3.4")
             )

    assert diff =~
             """
             @@ -33,7 +33,7 @@
                # Type `mix help deps` for examples and options.
                defp deps do
                  [
             -      {:phoenix, "~> 1.3.3"},
             +      {:phoenix, "~> 1.3.4"},
                    {:phoenix_pubsub, "~> 1.0"},
                    {:phoenix_ecto, "~> 3.2"},
                    {:postgrex, ">= 0.0.0"},
             """
  end

  test "the appropriate diff is returned when generating phoenix 1.0.x apps" do
    Gen.Sample.run(["1.0.3"])

    Gen.Sample.run(["1.0.4"])

    assert {:ok, diff} =
             Diffs.get_diff(
               Diffs.fetch_default_app_specification!("1.0.3"),
               Diffs.fetch_default_app_specification!("1.0.4")
             )

    assert diff =~
             """
             @@ -30,7 +30,7 @@
                #
                # Type `mix help deps` for examples and options.
                defp deps do
             -    [{:phoenix, "~> 1.0.3"},
             +    [{:phoenix, "~> 1.0.4"},
                   {:phoenix_ecto, "~> 1.1"},
                   {:postgrex, ">= 0.0.0"},
                   {:phoenix_html, "~> 2.1"},
             """

    assert diff =~
             """
             -    :ok
             +    {:ok, conn: Phoenix.ConnTest.conn()}
             """
  end

  test "errors with an invalid version id" do
    Gen.Sample.run(["not_a_version"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == ~s|Invalid version: \"not_a_version\"|
  end

  test "errors with an unknown version" do
    Gen.Sample.run(["0.1.10"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg =~ ~s|Unknown version: "0.1.10"|
  end

  test "errors when a phoenix version isn't specified" do
    Gen.Sample.run([])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == "A phoenix version must be specified"
  end
end

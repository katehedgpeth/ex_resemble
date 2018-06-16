defmodule ExResemble.CompareTest do
  use ExUnit.Case, async: true
  alias ExResemble.{Compare, Folders}

  setup do
    ref_folder = Application.app_dir(:ex_resemble, "priv/references")
    tests_folder = Application.app_dir(:ex_resemble, "priv/tests")

    test_folder = make_test_folder(tests_folder)

    on_exit(fn ->
      {:ok, _} = File.rm_rf(tests_folder)
    end)

    {:ok, folders: %Folders{refs: ref_folder, tests: test_folder}}
  end

  def make_test_folder(parent) do
    datetime = NaiveDateTime.utc_now()

    name =
      [:year, :month, :day, :hour, :minute, :second]
      |> Enum.map(&(datetime |> Map.get(&1) |> Integer.to_string()))
      |> IO.iodata_to_binary()

    folder = Path.join(parent, name)

    :ok = File.mkdir_p(folder)

    folder
  end

  describe "compare" do
    test "returns :ok when images are the same", %{folders: folders} do
      file_name = "test_image_1.png"

      assert :ok =
               folders.refs
               |> Path.join(file_name)
               |> File.cp(Path.join(folders.tests, file_name))

      assert Compare.compare(%Compare{
               file_name: file_name,
               folders: folders
             }) == :ok
    end
  end
end

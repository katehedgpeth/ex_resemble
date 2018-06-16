defmodule ExResemble.CompareTest do
  use ExUnit.Case, async: true
  alias ExResemble.{Compare, Folders, Diff}

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

  describe "handle_call" do
    test ":get_diff replies with %Diff{}", %{folders: folders} do
      assert :ok =
               folders.refs
               |> Path.join("test_image_2.png")
               |> File.cp(Path.join(folders.tests, "test_image_1.png"))

      args = %Compare{file_name: "test_image_1.png", folders: folders}
      assert {:ok, pid} = GenServer.start_link(Compare, args)
      diff = GenServer.call(pid, :get_diff)
      assert %Diff{} = diff
      assert is_integer(diff.analysis_time)
      assert is_boolean(diff.is_same_dimensions)
      assert is_float(diff.mismatch_percentage)
      assert is_float(diff.raw_mismatch_percentage)

      assert %{
               "bottom" => _,
               "top" => _,
               "left" => _,
               "right" => _
             } = diff.diff_bounds

      assert is_integer(diff.diff_bounds["bottom"])
      assert is_integer(diff.diff_bounds["top"])
      assert is_integer(diff.diff_bounds["left"])
      assert is_integer(diff.diff_bounds["right"])

      assert %{
               "height" => _,
               "width" => _
             } = diff.dimension_difference

      assert is_integer(diff.dimension_difference["height"])
      assert is_integer(diff.dimension_difference["width"])
    end
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

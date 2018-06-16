defmodule Mix.Tasks.ExResembleTest do
  use ExUnit.Case

  setup do
    ref_folder = Application.app_dir(:ex_resemble, "priv/references")
    tests_folder = Application.app_dir(:ex_resemble, "priv/tests")

    test_folder = make_test_folder(tests_folder)

    on_exit(fn ->
      {:ok, _} = File.rm_rf(test_folder)
    end)

    {:ok, ref_folder: ref_folder, test_folder: test_folder}
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


  describe "run/1" do
    test "returns :ok when all tests pass", %{ref_folder: refs, test_folder: tests} do
      assert {:ok, ref_files} = File.ls(refs)
      assert length(ref_files) > 1
      for file_name <- ref_files do
        assert :ok =
                 refs
                 |> Path.join(file_name)
                 |> File.cp(Path.join(tests, file_name))
      end

      assert Mix.Tasks.ExResemble.run(["--refs=#{refs}", "--tests=#{tests}"]) == :ok
    end

    test "returns {:error, error} when tests fail", %{ref_folder: refs, test_folder: tests} do
      {:ok, ref_files} = File.ls(refs)
      assert length(ref_files) > 1

      assert :ok =
                refs
                |> Path.join("test_image_1.png")
                |> File.cp(Path.join(tests, "test_image_1.png"))
      assert :ok =
                refs
                |> Path.join("test_image_1.png")
                |> File.cp(Path.join(tests, "test_image_2.png"))

      assert_raise ExResemble.Error, fn -> Mix.Tasks.ExResemble.run(["--refs=#{refs}", "--tests=#{tests}"]) end
    end
  end
end

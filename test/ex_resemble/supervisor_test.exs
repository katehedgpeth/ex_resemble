defmodule ExResemble.SupervisorTest do
  use ExUnit.Case
  alias ExResemble.{Supervisor, Folders}

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

  test "start_link" do
    assert {:ok, pid} = Supervisor.start_link([])
    assert is_pid(pid)
  end

  describe "init" do
    test "creates state struct", %{} do
      assert {:ok, %Supervisor{}} = Supervisor.init([])
    end

    test "does not overwrite folders if they are provided" do
      ref_folder = Application.app_dir(:ex_resemble)
      assert {:ok, %Supervisor{folders: %Folders{refs: default_folder}}} = Supervisor.init([])

      assert {:ok, %Supervisor{folders: %Folders{refs: ^ref_folder}}} =
               Supervisor.init(folders: [refs: ref_folder])

      refute default_folder == ref_folder
    end
  end

  describe "handle_call" do
    test ":state returns state" do
      {:ok, pid} = Supervisor.start_link([])
      assert GenServer.call(pid, :state) == %Supervisor{}
    end

    test ":run runs tests", %{ref_folder: refs, test_folder: test} do
      {:ok, ref_files} = File.ls(refs)
      assert length(ref_files) > 1

      for file_name <- ref_files do
        assert :ok =
                 refs
                 |> Path.join(file_name)
                 |> File.cp(Path.join(test, file_name))
      end

      {:ok, pid} = Supervisor.start_link(folders: [refs: refs, tests: test])
      GenServer.call(pid, :run)
    end
  end
end

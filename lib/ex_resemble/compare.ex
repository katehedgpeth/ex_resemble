defmodule ExResemble.Compare do
  alias ExResemble.{Folders, Diff}

  defstruct [:file_name, folders: %Folders{}]

  @type t :: %__MODULE__{
          file_name: String.t() | nil,
          folders: Folders.t()
        }

  @spec compare(t) :: :ok
  def compare(
        %__MODULE__{
          file_name: <<file_name::binary>>,
          folders: %Folders{refs: <<refs::binary>>, tests: <<tests::binary>>}
        } = args
      ) do
    {:ok, ref} =
      refs
      |> Path.join(file_name)
      |> File.read()

    tests
    |> Path.join(file_name)
    |> File.read()
    |> do_compare(ref, args)
  end

  @spec do_compare({:ok, String.t()} | {:error, any}, String.t(), t) :: :ok | {:error, Diff.t()}
  defp do_compare({:ok, test}, ref, %__MODULE__{}) when test == ref do
    :ok
  end

  defp do_compare({:ok, _test}, _ref, %__MODULE__{} = args) do
    {:ok, pid} = GenServer.start_link(__MODULE__, args)
    diff = GenServer.call(pid, :get_diff)
    {:error, diff}
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(:get_diff, _from, %__MODULE__{} = args) do
    :ok = File.mkdir_p(args.folders.diffs)
    ref_path = Path.join(args.folders.refs, args.file_name)
    test_path = Path.join(args.folders.tests, args.file_name)
    diff_path = Path.join(args.folders.diffs, "diff_" <> args.file_name)
    js_file = Application.app_dir(:ex_resemble, "priv/resemble.js")
    node_args = [
      js_file,
      ref_path,
      test_path,
      diff_path,
      :ex_resemble
      |> Application.get_env(:node_modules)
      |> Path.join("resemblejs")
    ]
    {result, 0} = System.cmd("node", node_args)

    {:reply, Diff.parse(result), args}
  end
end

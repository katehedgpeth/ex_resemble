defmodule ExResemble.Supervisor do
  use GenServer
  alias ExResemble.{Compare, Folders}

  defstruct [
    :caller,
    :current_test,
    pending: [],
    failed: [],
    folders: %Folders{}
  ]

  @type t :: %__MODULE__{
          caller: {reference, pid} | nil,
          current_test: String.t() | nil,
          folders: Folders.t(),
          pending: [String.t()],
          failed: [String.t()]
        }

  @spec start_link(Keyword.t()) :: {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl GenServer
  def init(opts) do
    state =
      opts
      |> Keyword.put_new(:folders, [])
      |> Keyword.update!(:folders, &Folders.__struct__/1)
      |> __MODULE__.__struct__()

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:run, from, %__MODULE__{folders: %Folders{refs: <<_::binary>>}} = state) do
    {:ok, files} = File.ls(state.folders.refs)
    send(self(), :run_test)
    {:noreply, %{state | caller: from, pending: files}}
  end

  def handle_call(:state, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(
        :run_test,
        %__MODULE__{caller: from, current_test: nil, pending: [], failed: []} = state
      ) do
    # all tests have run and no tests failed
    :ok = GenServer.reply(from, :ok)
    {:noreply, state}
  end

  def handle_info(
        :run_test,
        %__MODULE__{caller: from, current_test: nil, pending: [], failed: [_ | _]} = state
      ) do
    # all tests have run, but some tests failed
    :ok = GenServer.reply(from, {:error, state.failed})
  end

  def handle_info(:run_test, %__MODULE__{current_test: {_, %Task{}}} = state) do
    # a test is currently running; wait for it to finish before running another one
    {:noreply, state}
  end

  def handle_info(:run_test, %__MODULE__{current_test: nil, pending: [next | rest]} = state) do
    # another test is ready to be run
    task =
      Task.async(fn ->
        Compare.compare(%Compare{
          file_name: next,
          folders: state.folders
        })
      end)

    {:noreply, %{state | current_test: {next, task}, pending: rest}}
  end

  def handle_info({ref, :ok}, %__MODULE__{current_test: {_, %Task{ref: ref}}} = state) do
    send(self(), :run_test)
    {:noreply, %{state | current_test: nil}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, %__MODULE__{} = state) do
    {:noreply, state}
  end
end

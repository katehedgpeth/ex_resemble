defmodule ExResemble.Supervisor do
  use GenServer
  alias ExResemble.{Compare, Folders, Diff}

  @spec start_link(ExResemble.t()) :: {:ok, pid}
  def start_link(%ExResemble{} = opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl GenServer
  def init(%ExResemble{} = state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:run, from, %ExResemble{folders: %Folders{refs: <<_::binary>>}} = state) do
    {:ok, files} = File.ls(state.folders.refs)
    send(self(), :run_test)
    {:noreply, %{state | caller: from, pending: files}}
  end

  def handle_call(:state, _from, %ExResemble{} = state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(
        :run_test,
        %ExResemble{caller: from, current_test: nil, pending: [], failed: []} = state
      ) do
    # all tests have run and no tests failed
    :ok = GenServer.reply(from, :ok)
    {:noreply, state}
  end

  def handle_info(
        :run_test,
        %ExResemble{caller: from, current_test: nil, pending: [], failed: [_ | _]} = state
      ) do
    # all tests have run, but some tests failed
    :ok = GenServer.reply(from, {:error, state.failed})
    {:noreply, state}
  end

  def handle_info(:run_test, %ExResemble{current_test: {_, %Task{}}} = state) do
    # a test is currently running; wait for it to finish before running another one
    {:noreply, state}
  end

  def handle_info(:run_test, %ExResemble{current_test: nil, pending: [next | rest]} = state) do
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

  def handle_info({ref, :ok}, %ExResemble{current_test: {_, %Task{ref: ref}}} = state) do
    send(self(), :run_test)
    {:noreply, %{state | current_test: nil}}
  end
  def handle_info({ref, {:error, %Diff{} = diff}}, %ExResemble{current_test: {file, %Task{ref: ref}}} = state) do
    send(self(), :run_test)
    {:noreply, %{state | current_test: nil, failed: [{file, diff} | state.failed]}}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, %ExResemble{} = state) do
    {:noreply, state}
  end
end

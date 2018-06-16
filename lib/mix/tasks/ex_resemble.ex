defmodule Mix.Tasks.ExResemble do
  @moduledoc """
  Documentation for ExResemble.
  """

  use Mix.Task
  alias ExResemble.Supervisor

  @doc """
  """
  def run(args) do
    {opts, [], []} = OptionParser.parse(args, strict: [refs: :string, tests: :string])
    {:ok, refs} = Keyword.fetch(opts, :refs)
    {:ok, tests} = Keyword.fetch(opts, :tests)
    {:ok, pid} = GenServer.start_link(Supervisor, [folders: [refs: refs, tests: tests]])
    case GenServer.call(pid, :run) do
      :ok -> :ok
      {:error, diffs} -> raise ExResemble.Error, diffs: diffs
    end
  end
end

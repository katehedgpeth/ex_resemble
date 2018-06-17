defmodule Mix.Tasks.ExResemble do
  @moduledoc """
  Documentation for ExResemble.
  """

  use Mix.Task
  alias ExResemble.{Supervisor, Diff}

  @doc """
  """
  @impl Mix.Task
  def run(args) do
    {opts, [], []} = OptionParser.parse(args, switches: [refs: :string, tests: :string, html: :boolean])
    {:ok, refs} = Keyword.fetch(opts, :refs)
    {:ok, tests} = Keyword.fetch(opts, :tests)
    {:ok, pid} = GenServer.start_link(Supervisor, [folders: [refs: refs, tests: tests]])
    case GenServer.call(pid, :run) do
      :ok ->
        [:green, "All tests passed!  :)"]
        |> IO.ANSI.format()
        |> IO.puts()
        :ok

      {:error, diffs} ->
        [:red, "Some tests failed  :("]
        |> IO.ANSI.format()
        |> IO.puts()

        opts
        |> Keyword.get(:html)
        |> write_report(diffs, GenServer.call(pid, :state))
        |> open_report(opts)

        raise ExResemble.Error, diffs: diffs
    end
  end

  @spec write_report(boolean, [{String.t, Diff.t}], Supervisor.t) :: :ok
  def write_report(true, diffs, opts) do
    :ex_resemble
    |> Application.app_dir("priv")
    |> Path.join("report.eex")
    |> EEx.eval_file(diffs: Enum.map(diffs, &diff_to_html(&1, opts)))
    |> do_write_report()
  end
  def write_report(_, _, _) do
    :ok
  end

  defp do_write_report(html) do
    :ex_resemble
    |> Application.app_dir("priv/report.html")
    |> File.write(html)
  end

  @spec open_report(:ok, Keyword.t) :: :ok
  defp open_report(:ok, opts) do
    case Keyword.fetch(opts, :html) do
      {:ok, true} ->
        {"", 0} = System.cmd("open", [Application.app_dir(:ex_resemble, "priv/report.html")])
        :ok
      _ ->
        :ok
    end
  end

  def diff_to_html({file, %Diff{} = diff}, %Supervisor{folders: folders}) do
    :ex_resemble
    |> Application.app_dir("priv")
    |> Path.join("diff.eex")
    |> EEx.eval_file(file: file, diff: diff, folders: folders)
  end
end

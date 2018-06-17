defmodule ExResemble do
  @moduledoc """
  Documentation for ExResemble.
  """

  alias ExResemble.{Supervisor, Folders, Diff}

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

  @doc """
  """
  @spec run(Keyword.t) :: {:ok, t} | {:error, [Diff.t], t}
  def run(opts) do
    {:ok, pid} = GenServer.start_link(Supervisor, parse_opts(opts))

    result = GenServer.call(pid, :run)
    state = GenServer.call(pid, :state)

    case result do
      :ok ->
        {:ok, state}
      {:error, diffs} ->
        {:error, diffs, state}
    end
  end

  def parse_opts(opts) do
    opts
    |> Keyword.put_new(:folders, [])
    |> Keyword.update!(:folders, &Folders.__struct__/1)
    |> __MODULE__.__struct__()
  end

end

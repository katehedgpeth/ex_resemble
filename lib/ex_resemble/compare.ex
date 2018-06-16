defmodule ExResemble.Compare do
  alias ExResemble.Folders

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

  defp do_compare({:ok, test}, ref, %__MODULE__{}) when test == ref do
    :ok
  end

  defp do_compare({:ok, _test}, _ref, %__MODULE__{}) do
  end
end

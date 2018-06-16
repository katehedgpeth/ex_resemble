defmodule ExResemble.Folders do
  defstruct [:refs, :tests]

  @type t :: %__MODULE__{
          refs: String.t() | nil,
          tests: String.t() | nil
        }
end

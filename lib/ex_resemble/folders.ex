defmodule ExResemble.Folders do
  defstruct [
    :refs,
    :tests,
    diffs: Application.app_dir(:ex_resemble, "priv/diffs")
  ]

  @type t :: %__MODULE__{
          refs: String.t() | nil,
          tests: String.t() | nil,
          diffs: String.t() | nil
        }
end

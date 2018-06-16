defmodule ExResemble.Error do
  defexception [:message, :diffs]

  def exception(diffs: diffs) do
    msg = "some tests did not pass"
    %__MODULE__{message: msg, diffs: diffs}
  end
end

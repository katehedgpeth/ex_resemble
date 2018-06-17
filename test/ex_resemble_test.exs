defmodule ExResembleTest do
  use ExUnit.Case
  doctest ExResemble
  alias ExResemble.Folders

  describe "parse_opts/1" do
    test "creates state struct", %{} do
      assert %ExResemble{} = ExResemble.parse_opts([])
    end

    test "does not overwrite folders if they are provided" do
      ref_folder = Application.app_dir(:ex_resemble)
      assert %ExResemble{folders: %Folders{refs: default_folder}} = ExResemble.parse_opts([])

      assert %ExResemble{folders: %Folders{refs: ^ref_folder}} =
               ExResemble.parse_opts(folders: [refs: ref_folder])

      refute default_folder == ref_folder
    end
  end

end

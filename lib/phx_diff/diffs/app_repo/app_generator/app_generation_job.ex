defmodule PhxDiff.Diffs.AppRepo.AppGenerator.AppGenerationJob do
  @moduledoc false

  @type t :: %__MODULE__{
          base_path: String.t(),
          project_path: String.t(),
          tmp_path: String.t()
        }

  defstruct [:project_path, :tmp_path, :base_path]

  def new(base_path) when is_binary(base_path) do
    %__MODULE__{
      base_path: base_path,
      project_path: Path.join(base_path, "project"),
      tmp_path: Path.join(base_path, "tmp")
    }
  end
end

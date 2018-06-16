defmodule ExResemble.Diff do
  defstruct [
    :is_same_dimensions,
    :dimension_difference,
    :raw_mismatch_percentage,
    :mismatch_percentage,
    :diff_bounds,
    :analysis_time
  ]

  @type t :: %__MODULE__{}

  def parse(<<diff::binary>>) do
    diff
    |> Jason.decode()
    |> do_parse()
  end

  defp do_parse({:ok, %{"diff" => diff}}) do
    %__MODULE__{
      is_same_dimensions: is_same_dimensions(diff),
      dimension_difference: dimension_difference(diff),
      raw_mismatch_percentage: raw_mismatch_percentage(diff),
      mismatch_percentage: mismatch_percentage(diff),
      diff_bounds: diff_bounds(diff),
      analysis_time: analysis_time(diff)
    }
  end

  defp is_same_dimensions(%{"isSameDimensions" => result}), do: result

  defp dimension_difference(%{"dimensionDifference" => result}), do: result

  defp raw_mismatch_percentage(%{"rawMisMatchPercentage" => result}), do: result

  defp mismatch_percentage(%{"misMatchPercentage" => result}), do: String.to_float(result)

  defp analysis_time(%{"analysisTime" => result}), do: result

  defp diff_bounds(%{"diffBounds" => result}), do: result
end

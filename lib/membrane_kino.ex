defmodule Membrane.Kino do
  @moduledoc """
  Membrane Kino dashboard utilities.
  """

  defdelegate pipeline_graph(pipeline), to: __MODULE__.PipelineGraph, as: :new
  defdelegate pipeline_tree(pipeline, opts \\ []), to: __MODULE__.PipelineTree, as: :new

  @doc """
  Displays a pipeline dashboard, containing a `Membrane.Kino.PipelineGraph`
  and `Membrane.Kino.PipelineTree`.

  Clicking on an element in the graph or tree opens `Membrane.Kino.ComponentInfo`
  displaying details & metrics for that element.

  For usage example, see Readme.
  """
  @spec pipeline_dashboard(pipeline :: pid, graph: boolean(), tree: boolean()) :: Kino.Render.t()
  def pipeline_dashboard(pipeline, opts \\ []) do
    opts = Keyword.validate!(opts, graph: true, tree: true)

    component_info = __MODULE__.ComponentInfo.new(pipeline)

    graph =
      if opts[:graph],
        do: [__MODULE__.PipelineGraph.new(pipeline, component_info: component_info)],
        else: []

    tree =
      if opts[:tree],
        do: [__MODULE__.PipelineTree.new(pipeline, component_info: component_info)],
        else: []

    Kino.Layout.grid(graph ++ tree ++ [component_info])
  end
end

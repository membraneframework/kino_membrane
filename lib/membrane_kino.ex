defmodule Membrane.Kino do
  defdelegate pipeline_graph(pipeline), to: __MODULE__.PipelineGraph, as: :new
  defdelegate pipeline_tree(pipeline, opts \\ []), to: __MODULE__.PipelineTree, as: :new

  def pipeline_dashboard(pipeline, opts \\ []) do
    opts = Keyword.validate!(opts, graph: true, tree: true)

    component_info = __MODULE__.ComponentInfo.new(pipeline)

    Kino.Layout.grid(
      if(opts[:graph],
        do: [__MODULE__.PipelineGraph.new(pipeline, component_info: component_info)],
        else: []
      ) ++
        if(opts[:tree],
          do: [__MODULE__.PipelineTree.new(pipeline, component_info: component_info)],
          else: []
        ) ++
        [component_info]
    )
  end
end

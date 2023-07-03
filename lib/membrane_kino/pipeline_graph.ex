defmodule Membrane.Kino.PipelineGraph do
  @moduledoc """
  Displays a graph of the given pipeline.

  The graph allows to:

    - Zoom in/out using mouse scroll (after clicking the graph at least once)
    - Expand bins (the green squares) by either clicking + or double tapping (this will zoom in to fit the expanded bin as well)
    - Move components when holding Alt/Option
    - Select multiple components when holding Shift
    - If the layout is not readable enough, clicking Refresh layout may help
    - Clicking on a component reveals it in a component info view below the graph
    - Clicking the zoom (+) button of the Livebook cell extends the graph to cover full page width

  """
  use Kino.JS, assets_path: "assets/precompiled/graph"
  use Kino.JS.Live

  require Membrane.Kino.JSUtils, as: JSUtils

  alias Membrane.Kino.ComponentInfo

  JSUtils.precompiled_asset("assets", "precompiled/graph/main.js")

  @spec new(pipeline :: pid, component_info: ComponentInfo.t()) :: Kino.Render.t()
  def new(pipeline, opts \\ []) do
    Kino.JS.Live.new(__MODULE__, {pipeline, opts})
  end

  @impl true
  def init({pipeline, opts}, ctx) do
    opts = Keyword.validate!(opts, component_info: nil)
    {:ok, assign(ctx, [pipeline: pipeline, debounce_timer: nil, add: [], remove: []] ++ opts)}
  end

  @impl true
  def handle_connect(ctx) do
    component_info =
      ctx.assigns.component_info || ComponentInfo.new(ctx.assigns.pipeline) |> Kino.render()

    ctx.assigns.pipeline
    |> Membrane.Core.Pipeline.get_observer()
    |> Membrane.Core.Observer.subscribe([:graph])

    {:ok, [], assign(ctx, component_info: component_info)}
  end

  @impl true
  def handle_info({:graph, action, graph}, ctx) do
    graph = Enum.map(graph, &serialize_graph_entry/1)

    case action do
      :add -> broadcast_event(ctx, "update_graph", [graph, []])
      :remove -> broadcast_event(ctx, "update_graph", [[], graph])
    end

    {:noreply, ctx}
  end

  @impl true
  def handle_event("component_selected", id, ctx) do
    ComponentInfo.set_component(ctx.assigns.component_info, JSUtils.parse_term(id))
    {:noreply, ctx}
  end

  defp serialize_graph_entry(%{entity: :component, type: type, path: path}) do
    {parent_path, [label]} = Enum.split(path, -1)

    parent =
      case parent_path do
        [_pipeline] -> nil
        parent_path -> JSUtils.serialize_term(parent_path)
      end

    %{
      group: :nodes,
      data: %{
        type => true,
        id: JSUtils.serialize_term(path),
        label: JSUtils.serialize_label(label),
        parent: parent
      }
    }
  end

  defp serialize_graph_entry(%{entity: :link, from: from, to: to, output: output, input: input}) do
    %{
      group: :edges,
      data: %{
        id: JSUtils.serialize_term({from, output, input, to}),
        source: JSUtils.serialize_term(from),
        target: JSUtils.serialize_term(to)
      }
    }
  end
end

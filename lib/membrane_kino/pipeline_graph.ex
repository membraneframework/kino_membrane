defmodule Membrane.Kino.PipelineGraph do
  use Kino.JS
  use Kino.JS.Live

  alias Membrane.Kino.ComponentInfo

  require Membrane.Kino.JSUtils, as: JSUtils

  @graph_js JSUtils.precompiled_asset("assets/precompiled/graph.js")

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
      ctx.assigns.component_info || ComponentInfo.new(ctx.assigns.pipeline) |> tap(&Kino.render/1)

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

  asset "graph.js" do
    @graph_js
  end

  asset "main.js" do
    """
    import "./graph.js";

    export function init(ctx) {
      ctx.root.innerHTML = `
      <div id="graphContainer" style="height:400px;overflow:hidden;border:1px solid black;border-radius:15px"></div>
      `
      const graphContainer = document.querySelector("#graphContainer");
      // using CSS aspect-ratio resulted in unwanted padding under the Livebook's iframe
      const setGraphSize = () => {
        graphContainer.style.width = window.innerWidth - 10 + "px";
        graphContainer.style.height = Math.round(window.innerWidth * 10 / 16) + "px";
      }
      setGraphSize();
      window.addEventListener("resize", setGraphSize);
      const mg = new MembraneGraph({container: graphContainer, onClick: (node) => {
          if (node.element) {
              ctx.pushEvent("component_selected", node.id)
            }
          }
        });
      ctx.handleEvent("update_graph", ([add, remove]) => {
        mg.update(add, remove)
      });
    }
    """
  end
end

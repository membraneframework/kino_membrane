defmodule Membrane.Kino.PipelineTree do
  @moduledoc """
  Pipeline tree is a simple tree view that allows to explore a pipeline in a parent-child manner.

  By default it shows top-level elements and bins, and once you click on a bin it reveals its children.
  Clicking on an element reveals it in a component info view below the tree.
  """

  use Kino.JS
  use Kino.JS.Live

  require Membrane.Kino.JSUtils, as: JSUtils

  alias Membrane.Kino.ComponentInfo

  @tree_view_js JSUtils.precompiled_asset("assets/tree_view/", "precompiled/bundle.js")

  @spec new(pipeline :: pid, component_info: ComponentInfo.t()) :: Kino.Render.t()
  def new(pipeline, opts \\ []) do
    Kino.JS.Live.new(__MODULE__, {pipeline, opts})
  end

  @impl true
  def init({pipeline, opts}, ctx) do
    opts = Keyword.validate!(opts, component_info: nil)
    observer = Membrane.Core.Pipeline.get_observer(pipeline)
    {:ok, assign(ctx, [pipeline: pipeline, observer: observer] ++ opts)}
  end

  @impl true
  def handle_connect(ctx) do
    component_info =
      ctx.assigns.component_info || ComponentInfo.new(ctx.assigns.pipeline) |> Kino.render()

    Membrane.Core.Observer.subscribe(ctx.assigns.observer, graph: [entity: :component])
    {:ok, [], assign(ctx, component_info: component_info)}
  end

  @impl true
  def handle_info({:graph, action, graph}, ctx) do
    graph = Enum.flat_map(graph, &serialize_graph_entry/1)

    case action do
      :add -> broadcast_event(ctx, "update_tree", [graph, []])
      :remove -> broadcast_event(ctx, "update_tree", [[], graph])
    end

    {:noreply, ctx}
  end

  @impl true
  def handle_event("component_selected", id, ctx) do
    ComponentInfo.set_component(ctx.assigns.component_info, JSUtils.parse_term(id))
    {:noreply, ctx}
  end

  defp serialize_graph_entry(%{entity: :component, path: path, type: type}) do
    {parent_path, [name]} = Enum.split(path, -1)

    [
      %{
        label: JSUtils.serialize_label(name),
        name: JSUtils.serialize_term(name),
        id: JSUtils.serialize_term(path),
        parent_path: serialize_path(parent_path),
        type: type
      }
    ]
  end

  defp serialize_path(path) do
    path |> Enum.drop(1) |> Enum.map(&JSUtils.serialize_term/1)
  end

  asset "tree_view.js" do
    File.read!(@tree_view_js)
  end

  asset "main.js" do
    """
    import "./tree_view.js";

    export function init(ctx) {
      ctx.root.innerHTML = `
      <div id="treeContainer" style="width:calc(100% - 10px);padding-top:5px;padding-bottom:5px;border:1px solid black;border-radius:15px;min-height:50px;max-height:200px;overflow-x:clip;overflow-y:auto;"></div>
      `
      const tree = new MembraneComponentTree({
        domNode: document.querySelector("#treeContainer"),
        onClick: (node) => {
          if (node.type == "element") {
              ctx.pushEvent("component_selected", node.id)
            }
          }
      });
      ctx.handleEvent("update_tree", ([add, remove]) => {
        tree.update(add, remove)
      });
    }
    """
  end
end

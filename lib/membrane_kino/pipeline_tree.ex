defmodule Membrane.Kino.PipelineTree do
  use Kino.JS
  use Kino.JS.Live

  alias Membrane.Kino.{ComponentInfo, JSUtils}

  @tree_view_path Path.join(:code.priv_dir(:membrane_kino_dashboard), "tree_view.js")
  @external_resource @tree_view_path

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
      ctx.assigns.component_info || ComponentInfo.new(ctx.assigns.pipeline) |> tap(&Kino.render/1)

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
    File.read!(@tree_view_path)
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
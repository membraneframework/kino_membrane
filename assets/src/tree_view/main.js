import MembranePipelineTree from "./tree_view";

export function init(ctx) {
  ctx.root.innerHTML = `
  <div id="treeContainer" style="width:calc(100% - 10px);padding-top:5px;padding-bottom:5px;border:1px solid black;border-radius:15px;min-height:50px;max-height:200px;overflow-x:clip;overflow-y:auto;"></div>
  `
  const tree = new MembranePipelineTree({
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
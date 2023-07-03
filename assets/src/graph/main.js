import MembranePipelineGraph from "./graph.js";

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
  const mg = new MembranePipelineGraph({
    container: graphContainer, onClick: (node) => {
      if (node.element) {
        ctx.pushEvent("component_selected", node.id)
      }
    }
  });
  ctx.handleEvent("update_graph", ([add, remove]) => {
    mg.update(add, remove)
  });
}
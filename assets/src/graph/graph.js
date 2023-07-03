import cytoscape from 'cytoscape'
import fcose from 'cytoscape-fcose'
import expandCollapse from 'cytoscape-expand-collapse'

// Configuration of cytoscape layout
const layoutOpts = {
  name: 'fcose',
  animate: false,
  randomize: false,
  quality: 'proof',
  minEdgeLength: 50,
}

const expandCollapseOpts = {
  // Configuration of the layout to be used after each expand / collapse
  layoutBy: {
    name: "fcose",
    animate: true,
    animationDuration: defaultAnimationDuration,
    randomize: false,
    fit: false,
  },
  animate: false,
  fisheye: true,
  undoable: false,
  expandCueImage: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABmJLR0QA/wD/AP+gvaeTAAACOUlEQVRo3u1ZyU7CUBQlTguXDiuHnzAS2bEzhDZtSRqM7v0FjStW4B6NEv8A0yGpuHHhN0jwAxxWCq6pG70XaxQSwpvavmpvchNCoT3nDfeed5rJpJFGGtxhNs1pxTZyRVc7Uh3dKjr6veLob/D5HRM/w/XO4Br+xiptVSqVqdiBa662ptrGMYB7BpAflPmkuFqtYJVWIwdeaJrLMJoNAOEzAB9NH4icqZ66FAl41dV24aE9AcBHs1u0jZ3QgG809mdhqVyEAHwogcQ5PkvsqHvqPNz8Omzwv7KFzxQ38tGC/84bqG5z3ASiWDZjEzY3L/i92MD/kCgzgTdsYxFu8Bo7Aah4TCU2qPNMDx0XzJXJ0U/pGhV0R54mJZoAYoFZWCcffZQHHNMeAgHcCzUi8CiyBjpFNgKgt1A0klSeHO/GC4XAV2YnEkC5KysBWNqHJDNgSzsDtnFJQqDDA5I1iGbA0duTCRBK5TgIYGMlIeBLTKD/LwgkfAklfhMnvYzK3MgA28FkIQemk7Sd2Cptkoq5RwkJPBC7eShdJSRQTfKBpq94ygrdgR4cAYkI1KnPxNtNc0GSQ32X2TdFrzJuAoDB5PKG0KuM0RM6EfPywtGdqMGDC36Vv83PiDR3WxES8ISZu0MmL0dlolk2wkZ+THkth1SdXrg3LI1vinbfoMHwA8d71LFsR/6uDLtjIDtYtBP+p0rdYcOIQABm0bdBzY4Hj+Bk5wfZg+/v8BpKYlSVUrxmTSONPxCf9GPtiVNgCLQAAAAASUVORK5CYII=",
  collapseCueImage: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABmJLR0QA/wD/AP+gvaeTAAACNUlEQVRo3u1Zy07CQBQl6sadj5WPjzCRuQORBXZK2BsgfonPjQsfW40a/8FXDHyJhh9AXaj47kNwU+diTQiJ6dAO7aC9yQ1NSDvntHfu40wiEVtssQU2ZyMxYOs0ZTFYszR6ZjKomjo889/Pln9fVy1GTk1GV+35FMV7IgduZ+m0qdEdDu6Wu9Ol35iMbNtaeip04O8Mxg0djjiIpg/gnd6wGD18y6fHQgFvMLrIF32UALzT64ZOSr2L82x2yH3rTi+d75MDXEsu+HR6mD+80mvwbV7GNeWALxYHDQbnIYL/8YqULxFG2PwaTjrsy9iwTpTOMRR8gce0hpkhagKY8TBt91XoBA6lVoWVU6RkeaOriu22B45KzjPhlnBjxm+4Vo0A9luY0r3Dh3eVCoJvua0lwZOApcG6qgRMDZYFcn8kVVewT4IT7w2Mw4jAw2SbGAlyJULgSV0CUBch0FSYQONfEOj7EOrvTezKImqmUR2OvQlwbUfZQsZgybuV4KKTsl8gB8l+buZqwmoeKmbKtdM6bHY70DRUGmis3NxkV1MZyn3qEKB7/oZ6DR4UIHD/msmM+tSESCn62CcLgbQh1CqjI0B2pUiLEVXnijSR1xV3yyEqEBfSxN12eR0FpjAyjpD6EEAvLWBm6AH4u8AbVtQwrblfQ0ax+8C3/pKdGQn9rAyrIypmPnunGrYHVn52Qo1jVi46mTpZQekDBw93smu6jteXrf+4tsNTM1HimDW22P6AfQExbP9jIk1/vwAAAABJRU5ErkJggg=="
};

// Options to override the expand collapse options when programatically expanding / collapsing
// so that nodes' positions remain intact
const expandCollapseMungeOpts = { layoutBy: null, fisheye: false };

const defaultAnimationDuration = 300;

const cyStyle = [
  {
    selector: 'node',
    style: {
      'overlay-opacity': 0,
      'background-color': '#636fb1',
      'background-opacity': 0.8,
      'border-color': '#636fb1',
      label: 'data(label)',
      width: 70,
      height: 20,
      "shape": "rectangle",
      "font-size": 4,
      'z-index-compare': 'manual',
      // Modified so that nodes that are not parents hide behind their siblings that are parents
      // in case they overlap
      'z-index': (node) => node.ancestors().length * 10 + 1,
      'z-compound-depth': 'orphan'
    }
  },
  {
    selector: 'node:parent',
    style: {
      'background-opacity': 0.66,
      'background-color': 'lightgray',
      'text-margin-y': '10px',
      'border-color': 'green',
      "font-size": 8,
      'z-index': (node) => node.ancestors().length * 10 + 2,
    }
  },
  {
    selector: "node.cy-expand-collapse-collapsed-node",
    style: {
      "background-color": "green",
      'border-color': 'green',
      "shape": "rectangle",
      'text-halign': 'center',
      'text-valign': 'center',
    }
  },
  {
    selector: "[element]",
    style: {
      'text-halign': 'center',
      'text-valign': 'center',
    }
  },
  {
    selector: 'edge',
    style: {
      'width': 1,
      'line-color': '#6368b1',
      'curve-style': 'bezier',
      'control-point-step-size': 10,
      'target-arrow-shape': 'triangle',
      'target-arrow-color': '#6368b1',
      'arrow-scale': '0.5',
      // Modified so that edges were behind nodes if they overlap,
      // so that edges didn't block nodes from being interacted with mouse.
      // Edges are still visible becouse of nodes' background transparency
      'z-index': (edge) => (
        Math.max(edge.source().ancestors().length, edge.target().ancestors().length) * 10
      ),
      'z-index-compare': 'manual',
      'z-compound-depth': 'orphan',
      'overlay-opacity': 0,
    }
  },
  {
    selector: 'edge.meta',
    style: {
      'width': 2,
      'line-color': 'red'
    }
  },
  {
    selector: ':selected',
    style: {
      'border-style': 'dashed',
      'border-width': '1px',
    }
  }
]

const areNodesInViewport = (cy, nodes) => {
  const ext = cy.extent()
  return nodes.every(node => {
    const bb = node.boundingBox();
    return bb.x1 > ext.x1 && bb.x2 < ext.x2 && bb.y1 > ext.y1 && bb.y2 < ext.y2;
  });
}

// This enables panning instead of moving nodes when dragging with mouse
// whenever `enabled()` returns true.
function globalPanning(cy, enabled) {
  let startPosition;
  cy.on('mousedown', 'node, edge', (evt) => {
    if (enabled(evt) && evt.originalEvent.button === 0) {
      startPosition = evt.position;
    }
  });
  cy.on('mouseup', (evt) => {
    if (evt.originalEvent.button === 0) {
      startPosition = null;
    }
  });
  cy.on('mousemove', (evt) => {
    cy.autoungrabify(enabled(evt));
    if (evt.originalEvent.buttons != 1) {
      startPosition = null;
    }
    if (startPosition) {
      const zoom = cy.zoom();
      const relativePosition = {
        x: (evt.position.x - startPosition.x) * zoom,
        y: (evt.position.y - startPosition.y) * zoom,
      };
      cy.panBy(relativePosition);
    }
  });
}

// Used to postpone code execution, letting events already scheduled
// for execution to be executed first.
// It can be used to split long operations and avoid UI freezes,
// or as a workaround when a callback is executed before the needed
// state/context changes finish.
const scheduleForMainLoop = (fun) => setTimeout(fun, 5);

export default class MembraneGraph {

  // Used for handling double taps and checking if expand/collapse
  // was triggered by user or programatically
  interactedItem = null;
  interactionTimeout = null;

  // Set when graph update / programatically triggered animation is in
  // progress. When true, all other work needs to wait.
  workInProgress = false;

  // Set whenever layout change is in progress
  layoutInProgress = false;

  // Animation awaiting for some work to be finished (see workInProgress)
  awaitingAnimation = null;

  // Graph items to be added/removed when current work finishes (see workInProgress)
  awaitingAdd = [];
  awaitingRemove = [];

  constructor({ container, onClick }) {
    container.innerHTML = `
    <div style="width: 100%; height: 100%">
      <div class="menu-container" style="position: absolute;z-index: 1000;padding: 20px;">
        <svg id="expand" style="cursor:pointer;fill:#000;height:30px;width:30px;padding-right:2px;" version="1.1" id="Capa_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 469 469" xml:space="preserve" data-darkreader-inline-fill="" style="--darkreader-inline-fill: #000000;"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g> <g> <path d="M455.5,0h-442C6,0,0,6,0,13.5v211.9c0,7.5,6,13.5,13.5,13.5s13.5-6,13.5-13.5V27h415v415H242.4c-7.5,0-13.5,6-13.5,13.5 s6,13.5,13.5,13.5h213.1c7.5,0,13.5-6,13.5-13.5v-442C469,6,463,0,455.5,0z"></path> <path d="M175.6,279.9H13.5c-7.5,0-13.5,6-13.5,13.5v162.1C0,463,6,469,13.5,469h162.1c7.5,0,13.5-6,13.5-13.5V293.4 C189.1,286,183,279.9,175.6,279.9z M162.1,442H27V306.9h135.1V442z"></path> <path d="M360.4,127.7v71.5c0,7.5,6,13.5,13.5,13.5s13.5-6,13.5-13.5V95.1c0-7.5-6-13.5-13.5-13.5H269.8c-7.5,0-13.5,6-13.5,13.5 s6,13.5,13.5,13.5h71.5L212.5,237.4c-5.3,5.3-5.3,13.8,0,19.1c2.6,2.6,6.1,4,9.5,4s6.9-1.3,9.5-4L360.4,127.7z"></path> </g> </g> </g></svg>
        <svg id="collapse" style="cursor:pointer;fill:#000;height:32px;width:32px;" viewBox="0 0 512 512" data-name="Layer 1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" data-darkreader-inline-fill="" style="--darkreader-inline-fill: #000000;"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"><polygon points="364.52 199.26 333.95 199.26 408.52 124.69 387.31 103.48 312.74 178.05 312.74 147.48 282.74 147.48 282.74 229.26 364.52 229.26 364.52 199.26"></polygon><path d="M448,34H34V478H478V34Zm0,414H64V64H448Z"></path><polygon points="312.74 333.95 387.31 408.52 408.52 387.31 333.95 312.74 364.52 312.74 364.52 282.74 282.74 282.74 282.74 364.52 312.74 364.52 312.74 333.95"></polygon><polygon points="199.26 333.95 199.26 364.52 229.26 364.52 229.26 282.74 147.48 282.74 147.48 312.74 178.05 312.74 103.48 387.31 124.69 408.52 199.26 333.95"></polygon><polygon points="147.48 199.26 147.48 229.26 229.26 229.26 229.26 147.48 199.26 147.48 199.26 178.05 124.69 103.48 103.48 124.69 178.05 199.26 147.48 199.26"></polygon></g></svg>
        <svg id="refresh" style="cursor:pointer;fill:#000;height:32px;width:32px" version="1.1" id="Capa_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 489.935 489.935" xml:space="preserve" data-darkreader-inline-fill="" style="--darkreader-inline-fill: #000000; --darkreader-inline-stroke: #e8e6e3;" stroke="#000000" data-darkreader-inline-stroke=""><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g> <path d="M278.235,33.267c-116.7,0-211.6,95-211.6,211.7v0.7l-41.9-63.1c-4.1-6.2-12.5-7.9-18.7-3.8c-6.2,4.1-7.9,12.5-3.8,18.7 l60.8,91.5c2.2,3.3,5.7,5.4,9.6,5.9c0.6,0.1,1.1,0.1,1.7,0.1c3.3,0,6.5-1.2,9-3.5l84.5-76.1c5.5-5,6-13.5,1-19.1 c-5-5.5-13.5-6-19.1-1l-56.1,50.7v-1c0-101.9,82.8-184.7,184.6-184.7s184.7,82.8,184.7,184.7s-82.8,184.7-184.6,184.7 c-49.3,0-95.7-19.2-130.5-54.1c-5.3-5.3-13.8-5.3-19.1,0c-5.3,5.3-5.3,13.8,0,19.1c40,40,93.1,62,149.6,62 c116.6,0,211.6-94.9,211.6-211.7S394.935,33.267,278.235,33.267z"></path> </g> </g></svg>
      </div>

      <div id="cy" style="width: 100%; height: 100%"></div>
    </div>
    `

    cytoscape.use(fcose);
    expandCollapse(cytoscape);
    const cy = cytoscape({
      container: document.getElementById('cy'),
      layout: layoutOpts,
      autoungrabify: true,
      style: cyStyle,
      userZoomingEnabled: false,
      minZoom: 1,
      wheelSensitivity: 0.5,
    });

    globalPanning(cy, (e) => !e.originalEvent.altKey);

    const ec = cy.expandCollapse(expandCollapseOpts);

    document.getElementById("collapse").addEventListener("click", () => {
      ec.collapseAll();
      scheduleForMainLoop(() => this._animate({ fit: { padding: 50 } }));
    });

    document.getElementById("expand").addEventListener("click", () => {
      ec.expandAll();
      scheduleForMainLoop(() => this._animate({ fit: { padding: 50 } }));
    });

    document.getElementById("refresh").addEventListener("click", () => this.reLayout());

    window.addEventListener('resize', () => {
      scheduleForMainLoop(() => this._animate({ fit: { padding: 50 } }));
    });

    cy.on('tap', (event) => {
      const target = event.target;
      if (target.isNode && target.isNode()) {
        onClick?.(target.data());
      }
      target.data("interaction", "tap");
      if (this.interactionTimeout) {
        clearTimeout(this.interactionTimeout);
      }
      if (this.interactedItem === target) {
        target.data("interaction", "doubleTap");
        if (target.isNode && target.isNode()) {
          ec.expand(target);
        }
        this.interactedItem = null;
      } else {
        this.interactedItem = target;
      }
      this.interactionTimeout = setTimeout(() => {
        this.interactedItem = null;
        target.data("interaction", null);
      }, 300);
    });


    cy.on("expandcollapse.afterexpand", (event) => {
      scheduleForMainLoop(() => {
        const node = event.target;
        const parent = node.parent();
        const interaction = node.data("interaction");
        node.data("interaction", null);
        if (interaction == "doubleTap") {
          this._animate({ fit: { eles: node, padding: 50 } });
        } else if (interaction == "tap") {
          const eles = parent[0] ? parent : undefined;
          this._animate({ fit: { eles, padding: 50 } });
        }
      });
    });

    cy.on("expandcollapse.aftercollapse", (event) => {
      scheduleForMainLoop(() => {
        const node = event.target;
        if (node.data("interaction")) {
          node.data("interaction", null)
          const parent = node.parent();
          this._animate(() => {
            if (parent[0] && !areNodesInViewport(cy, parent)) {
              return { fit: { eles: parent, padding: 50 } };
            } else if (!parent[0] || areNodesInViewport(cy, cy.nodes())) {
              return { fit: { padding: 50 } };
            } else {
              return { center: { eles: parent } };
            }
          });
        }
      });
    });

    cy.on("layoutstart", () => {
      console.debug("layout start")
      this.layoutInProgress = true;
    });

    cy.on("layoutstop", () => {
      console.debug("layout stop")
      this.layoutInProgress = false;
      scheduleForMainLoop(() => {
        this._runAwaitingWork();
      });
    });

    document.querySelector("body").addEventListener('click', () => cy.userZoomingEnabled(true));
    document.querySelector("body").addEventListener('mouseleave', () => cy.userZoomingEnabled(false));

    ec.collapseRecursively(cy.nodes().filter(node => node.data().bin));

    scheduleForMainLoop(() => this._animate({ fit: { padding: 50 } }, { duration: 100 }));

    this.cy = cy;
    this.ec = ec;
    return this;
  };

  // Expands the whole graph, runs the layout and collapses back.
  // For some reason it often results in better layout.
  reLayout() {
    const { ec, cy } = this;
    const collapsed_children = ec.getAllCollapsedChildrenRecursively();
    const collapsed_parents = cy.elements(".cy-expand-collapse-collapsed-node");
    ec.expandAll(expandCollapseMungeOpts);
    cy.layout(layoutOpts).run();
    ec.collapse(collapsed_children, expandCollapseMungeOpts);
    ec.collapse(collapsed_parents, expandCollapseMungeOpts);
    cy.layout(layoutOpts).run();
  }

  update(add, remove) {
    this.awaitingAdd.push(...add);
    this.awaitingRemove.push(...remove);
    this._apply_update();
  }

  _apply_update() {
    if (!this._canWork()) {
      return;
    }
    if (this.awaitingAdd.length == 0 && this.awaitingRemove.length == 0) {
      return;
    }
    this.workInProgress = true;
    // Wait to avoid too many subsequent updates
    setTimeout(() => {
      console.debug("add graph data");
      const { ec, cy, awaitingAdd: add, awaitingRemove: remove } = this;
      this.awaitingAdd = [];
      this.awaitingRemove = [];
      // Only run the layout if the visible part of the graph changed
      const needLayoutRun = [...add, ...remove].some(({ group, data: { parent, source, target } }) =>
        (group == "nodes" && !parent) ||
        (group == "nodes" && cy.$id(parent)[0] && ec.isCollapsible(cy.$id(parent)[0])) ||
        (group == "edges" && (cy.$id(source)[0] || cy.$id(target)[0]))
      );
      needLayoutRun || cy.nodes().lock();
      const collapsed_children = ec.getAllCollapsedChildrenRecursively();
      const collapsed_parents = cy.elements(".cy-expand-collapse-collapsed-node");
      ec.expandAll(expandCollapseMungeOpts);
      console.debug("expanded data");
      // For small graphs, adding nodes one by one and running layout each time
      // seems to result in better layout. For big graphs it's too much work.
      if (needLayoutRun && cy.nodes().length + add.length < 20) {
        const new_elements = add.map(graphElement => {
          const element = cy.add([graphElement]);
          cy.layout(layoutOpts).run();
          return element;
        });
        remove.forEach(({ data: { id } }) => cy.remove(cy.$id(id)));
        console.debug("removed data");
        new_elements.forEach((e) => ec.collapse(e, expandCollapseMungeOpts));
      } else {
        console.debug("adding data");
        const new_elements = cy.add(add);
        console.debug("added data");
        remove.forEach(({ data: { id } }) => cy.remove(cy.$id(id)));
        console.debug("removed data");
        needLayoutRun && cy.layout(layoutOpts).run();
        console.debug("run layout");
        ec.collapse(new_elements, expandCollapseMungeOpts);
      }
      ec.collapse(collapsed_children, expandCollapseMungeOpts);
      ec.collapse(collapsed_parents, expandCollapseMungeOpts);
      console.debug("collapse");
      needLayoutRun && cy.layout(layoutOpts).run();
      console.debug("run layout again");
      needLayoutRun || cy.nodes().unlock();
      this.workInProgress = false;
      this._runAwaitingWork();
    }, 500);
  }

  _animate(animation, options) {
    if (!this._canWork()) {
      this.awaitingAnimation = { animation, options };
      return;
    }
    animation = animation instanceof Function ? animation() : animation;
    options = options || {};
    options.duration = options.duration || defaultAnimationDuration;
    const complete = options.complete;
    this.workInProgress = true;
    options.complete = (e) => {
      complete?.();
      this.workInProgress = false;
      this._runAwaitingWork();
    }
    console.debug("animating");
    this.cy.animate(animation, options);
  }

  _canWork() {
    return !this.layoutInProgress && !this.workInProgress;
  }

  _runAwaitingWork() {
    if (!this._canWork()) {
      return;
    }
    if (this.awaitingAnimation) {
      const { animation, options } = this.awaitingAnimation;
      this.awaitingAnimation = null;
      this._animate(animation, options);
      return;
    }
    this._apply_update();
  }

}

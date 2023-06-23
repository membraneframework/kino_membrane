import * as React from 'react';
import { useCallback } from 'react';
import { createRoot } from 'react-dom/client';
import TreeView from '@mui/lab/TreeView';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import TreeItem from '@mui/lab/TreeItem';

const RenderTree = ({ node: node, onClick: onClick }) => {
  const handleClick = useCallback((_event) => {
    onClick(node);
  }, [node])

  return <TreeItem
    nodeId={node.name}
    label={node.label}
    onClick={handleClick}>
    {node.children
      ? Object.values(node.children).map((node) => <RenderTree key={node.path} node={node} onClick={onClick} />)
      : null}
  </TreeItem>
}

const RichObjectTreeView = ({ data: data, onClick: onClick }) =>
  <TreeView
    aria-label="rich object"
    defaultCollapseIcon={<ExpandMoreIcon />}
    defaultExpandIcon={<ChevronRightIcon />}
  >
    {Object.values(data).map((node) => <RenderTree key={node.path} node={node} onClick={onClick} />)}
  </TreeView>

export class MembraneComponentTree {

  constructor({ domNode: domNode, onClick: onClick }) {
    this.data = {};
    this.root = createRoot(domNode);
    this._renderTree();
    this.onClick = onClick || (() => { })
  }

  update(add, remove) {
    add.forEach(({ name, id, label, parent_path, type }) => {
      let children = this.data;
      parent_path.forEach((parent) => {
        children = children[parent].children;
      });
      children[name] = {
        name: name,
        id: id,
        label: label,
        path: [...parent_path, name],
        type: type,
        children: {}
      }
    });

    remove.forEach(({ name: name, parent_path: parent_path }) => {
      let children = this.data;
      parent_path.forEach((parent) =>
        children = children[parent].children);
      delete children[name];
    })

    this._renderTree();
  }

  _renderTree() {
    this.root.render(<RichObjectTreeView data={this.data} onClick={this.onClick} />);
  }
}

window.MembraneComponentTree = MembraneComponentTree;

import * as React from 'react';
import { useCallback } from 'react';
import { createRoot } from 'react-dom/client';
import TreeView from '@mui/lab/TreeView';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import TreeItem from '@mui/lab/TreeItem';

const RenderTree = ({ node, onClick }) => {
  const handleClick = useCallback((_event) => {
    onClick(node);
  }, [node])

  return <TreeItem
    nodeId={node.name}
    label={node.label}
    onClick={handleClick}>
    {Object.values(node.children ?? {}).map((node) => <RenderTree key={node.path} node={node} onClick={onClick} />)}
  </TreeItem>
}

const RichObjectTreeView = ({ data, onClick }) =>
  <TreeView
    aria-label="rich object"
    defaultCollapseIcon={<ExpandMoreIcon />}
    defaultExpandIcon={<ChevronRightIcon />}
  >
    {Object.values(data).map((node) => <RenderTree key={node.path} node={node} onClick={onClick} />)}
  </TreeView>

export default class MembranePipelineTree {

  constructor({ domNode, onClick }) {
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
        name, id, label, type,
        path: [...parent_path, name],
        children: {}
      }
    });

    remove.forEach(({ name, parent_path }) => {
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

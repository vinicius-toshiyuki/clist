#define __TREE_NO_CONTROL__
#include <tree.h>
#undef __TREE_NO_CONTROL__
#include <util.h>

struct tree_controller T = {
    tree_new_node,
    tree_del_node,
    tree_add,
    tree_join,
    {tree_run_depth_pre, tree_run_depth_pos, tree_run_breadth}};

node_t tree_new_node(void *val) {
  node_t node = alloc(struct node);
  node->val = val;
  node->branches = NULL;
  node->top = NULL;
  return node;
}

void tree_del_node(node_t node) {
  if (node->top) {
    size_t pos = 0;
    list_map(if (node == Lval) break; pos++, node->top->branches);
    L.pop(pos, node->top->branches);
    if (node->top->branches->size == 0) {
      L.del(node->top->branches);
      node->top->branches = NULL;
    }
  }
  tree_del_sub_tree(node);
}

void tree_del_sub_tree(node_t node) {
  if (node->branches) {
    list_map(tree_del_sub_tree(Lval), node->branches);
    L.del(node->branches);
  }
  free(node);
}

node_t tree_add(void *val, node_t node) {
  node_t new_node = tree_new_node(val);
  tree_join(new_node, node);
  return new_node;
}

void tree_join(node_t branch, node_t tree) {
  if (!tree->branches)
    tree->branches = L.new();
  L.append(branch, tree->branches);
  branch->top = tree;
}

void tree_run_depth(void (*action)(node_t, void *), void *data, int mode,
                    node_t node) {
  if (mode == TREE_RUN_PRE)
    action(node, data);
  if (node->branches)
    list_map(tree_run_depth(action, data, mode, Lval), node->branches);
  if (mode == TREE_RUN_POS)
    action(node, data);
}

void tree_run_depth_pre(void (*action)(node_t, void *), void *data,
                        node_t node) {
  tree_run_depth(action, data, TREE_RUN_PRE, node);
}
void tree_run_depth_pos(void (*action)(node_t, void *), void *data,
                        node_t node) {
  tree_run_depth(action, data, TREE_RUN_POS, node);
}
void tree_run_breadth(void (*action)(node_t, void *), void *data, node_t node) {
  tree_breadth(action(Tval, data), node);
}

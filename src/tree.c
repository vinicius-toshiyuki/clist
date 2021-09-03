#define __TREE_NO_CONTROL__
#include <tree.h>
#undef __TREE_NO_CONTROL__
#include <util.h>

struct tree_controller T = {
    tree_new_node,
    tree_del_node,
    tree_add,
    tree_join,
    {tree_run_inorder, tree_run_postorder, tree_run_breadth},
    NULL,
    0};

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
    list_map(if (node == L.val) break; pos++, node->top->branches);
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
    list_map(tree_del_sub_tree(L.val), node->branches);
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

void tree_run_order(void (*action)(node_t, void *), void *data,
                    enum tree_run_order mode, node_t node) {
  if (mode == TREE_RUN_INORDER)
    action(node, data);
  if (node->branches)
    list_map(tree_run_order(action, data, mode, L.val), node->branches);
  if (mode == TREE_RUN_POSTORDER)
    action(node, data);
}

void tree_run_inorder(void (*action)(node_t, void *), void *data, node_t node) {
  tree_run_order(action, data, TREE_RUN_INORDER, node);
}
void tree_run_postorder(void (*action)(node_t, void *), void *data,
                        node_t node) {
  tree_run_order(action, data, TREE_RUN_POSTORDER, node);
}
void tree_run_breadth(void (*action)(node_t, void *), void *data, node_t node) {
  tree_breadth(action(T.val, data), node);
}

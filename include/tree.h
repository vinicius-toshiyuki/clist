#ifndef __TREE_H__
#define __TREE_H__

#include "list.h"

typedef struct node {
  void *val;
  struct node *top;
  list_t branches;
} * node_t;

struct tree_run_controller {
  void (*pre)(void (*)(node_t, void *), void *, node_t);
  void (*pos)(void (*)(node_t, void *), void *, node_t);
  void (*breadth)(void (*)(node_t, void *), void *, node_t);
};

enum { TREE_RUN_PRE, TREE_RUN_POS };

struct tree_controller {
  node_t (*new)(void *);
  void (*del)(node_t);
  node_t (*add)(void *, node_t);
  void (*join)(node_t, node_t);
  struct tree_run_controller run;
};

node_t tree_new_node(void *val);
void tree_del_node(node_t node);
void tree_del_sub_tree(node_t node);
node_t tree_add(void *val, node_t node);
void tree_join(node_t branch, node_t tree);

void tree_run_depth(void (*action)(node_t, void *), void *data, int mode,
                    node_t node);
void tree_run_depth_pre(void (*action)(node_t, void *), void *data,
                        node_t node);
void tree_run_depth_pos(void (*action)(node_t, void *), void *data,
                        node_t node);
void tree_run_breadth(void (*action)(node_t, void *), void *data, node_t node);

#define tree_breadth(code, node)                                               \
  {                                                                            \
    void *Tval = NULL;                                                         \
    node_t __breadth_current = NULL;                                           \
    list_t __breadth_to_visit = L.new();                                       \
    L.append(node, __breadth_to_visit);                                        \
    while (__breadth_to_visit->size > 0) {                                     \
      __breadth_current = L.pop_head(__breadth_to_visit);                      \
      if (__breadth_current->branches)                                         \
        list_map(L.append(Lval, __breadth_to_visit),                           \
                 __breadth_current->branches);                                 \
      Tval = __breadth_current->val;                                           \
      code;                                                                    \
    }                                                                          \
    L.del(__breadth_to_visit);                                                 \
  }

#endif

#ifndef __TREE_NO_CONTROL__
extern struct tree_controller T;
#endif

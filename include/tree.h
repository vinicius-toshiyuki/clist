#ifndef __TREE_H__
#define __TREE_H__

#include "list.h"

#ifndef new
#define new __new
#endif

typedef struct node {
  void *val;
  struct node *top;
  list_t branches;
} * node_t;

struct tree_run_controller {
  void (*inorder)(void (*)(node_t, void *), void *, node_t);
  void (*postorder)(void (*)(node_t, void *), void *, node_t);
  void (*breadth)(void (*)(node_t, void *), void *, node_t);
};
enum tree_run_order { TREE_RUN_INORDER, TREE_RUN_POSTORDER };
enum tree_del_mode { TREE_DEL_SOFT, TREE_DEL_HARD };

struct tree_controller {
  node_t (*new)(void *);
  void (*del)(node_t);
  void (*hard_del)(node_t);
  node_t (*add)(void *, node_t);
  void (*join)(node_t, node_t);
  struct tree_run_controller run;
  void *val;
  size_t lvl;
  enum tree_del_mode del_mode;
};

node_t tree_new_node(void *val);
void tree_del_node(node_t node);
void tree_del_sub_tree(node_t node);
void tree_hard_del_node(node_t node);
void tree_hard_del_sub_tree(node_t node);
node_t tree_add(void *val, node_t node);
void tree_join(node_t branch, node_t tree);

void tree_run_order(void (*action)(node_t, void *), void *data,
                    enum tree_run_order mode, node_t node);
void tree_run_inorder(void (*action)(node_t, void *), void *data, node_t node);
void tree_run_postorder(void (*action)(node_t, void *), void *data,
                        node_t node);
void tree_run_breadth(void (*action)(node_t, void *), void *data, node_t node);

/* TODO: T.lvl doesn't work for post order */
#define tree_order(code, node, ...)                                            \
  {                                                                            \
    __VA_OPT__(                                                                \
        if (strcmp(#__VA_ARGS__, "in") && strcmp(#__VA_ARGS__, "post")) {      \
          perror("Invalid run order\n");                                       \
          exit(EXIT_FAILURE);                                                  \
        } enum tree_run_order __tree_mode;                                     \
        list_t __tree_postorder = L.new();                                     \
        if (strcmp(#__VA_ARGS__, "in") == 0) __tree_mode = TREE_RUN_INORDER;   \
        else __tree_mode = TREE_RUN_POSTORDER;)                                \
    size_t __tree_order_lvl = T.lvl;                                           \
    void *__tree_order_val = T.val;                                            \
    T.lvl = (size_t)-1;                                                        \
    size_t __tree_order_dive_count = 0;                                        \
    node_t __tree_order_current = NULL, __tree_order_prev = NULL;              \
    list_t __tree_order_to_visit = L.new();                                    \
    L.append(node, __tree_order_to_visit);                                     \
    while (__tree_order_to_visit->size > 0) {                                  \
      __tree_order_current = L.pop_tail(__tree_order_to_visit);                \
      if (__tree_order_current->top == __tree_order_prev)                      \
        T.lvl++;                                                               \
      else if (__tree_order_prev->top != __tree_order_current->top)            \
        T.lvl -= __tree_order_dive_count, __tree_order_dive_count = 0;         \
      __tree_order_prev = __tree_order_current;                                \
      if (__tree_order_current->top &&                                         \
          __tree_order_current ==                                              \
              __tree_order_current->top->branches->tail->val)                  \
        __tree_order_dive_count++;                                             \
      if (__tree_order_current->branches) {                                    \
        __VA_OPT__(                                                            \
            if (__tree_mode == TREE_RUN_INORDER) { )                           \
      list_map(L.append(L.val, __tree_order_to_visit),                         \
               __tree_order_current->branches, tail);                          \
      __VA_OPT__(                                                              \
            } else {                                                           \
              list_map(L.append(L.val, __tree_order_to_visit),                 \
                       __tree_order_current->branches, head);                  \
            })                                                                 \
      }                                                                        \
      T.val = __tree_order_current->val;                                       \
      __VA_OPT__(if (__tree_mode == TREE_RUN_INORDER)) { code; }               \
      __VA_OPT__(else L.append(__tree_order_current, __tree_postorder);)       \
    }                                                                          \
    __VA_OPT__(if (__tree_mode == TREE_RUN_POSTORDER)                          \
                   list_map(T.val = as(L.val, node_t)->val;                    \
                            code, __tree_postorder, tail);)                    \
    L.del(__tree_order_to_visit);                                              \
    __VA_OPT__(L.del(__tree_postorder);)                                       \
    T.val = __tree_order_val;                                                  \
    T.lvl = __tree_order_lvl;                                                  \
  }

#define tree_inorder(code, node) tree_order(code, node)
#define tree_postorder(code, node) tree_order(code, node, post)

#define tree_breadth(code, node)                                               \
  {                                                                            \
    size_t __breadth_branches = 1, __breadth_next_branches = 0,                \
           __breadth_lvl = T.lvl;                                              \
    void *__breadth_val = T.val;                                               \
    T.lvl = 0;                                                                 \
    node_t __breadth_current = NULL;                                           \
    list_t __breadth_to_visit = L.new();                                       \
    L.append(node, __breadth_to_visit);                                        \
    while (__breadth_to_visit->size > 0) {                                     \
      __breadth_current = L.pop_head(__breadth_to_visit);                      \
      if (__breadth_current->branches) {                                       \
        __breadth_next_branches += __breadth_current->branches->size;          \
        list_map(L.append(L.val, __breadth_to_visit),                          \
                 __breadth_current->branches);                                 \
      }                                                                        \
      T.val = __breadth_current->val;                                          \
      { code; }                                                                \
      __breadth_branches--;                                                    \
      if ((!__breadth_current->top ||                                          \
           __breadth_current ==                                                \
               __breadth_current->top->branches->tail->val) &&                 \
          !__breadth_branches) {                                               \
        __breadth_branches = __breadth_next_branches;                          \
        __breadth_next_branches = 0, T.lvl++;                                  \
      }                                                                        \
    }                                                                          \
    L.del(__breadth_to_visit);                                                 \
    T.val = __breadth_val;                                                     \
    T.lvl = __breadth_lvl;                                                     \
  }

#endif

#ifndef __TREE_NO_CONTROL__
extern struct tree_controller T;
#endif

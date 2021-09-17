#include "../include/list.h"
#include "../include/slist.h"
#include "../include/tree.h"
#include "../include/util.h"
#include <stdio.h>

int main() {
  list_t list = L.new();
  for (int i = 0; i < 5; i++) {
    int *val = alloc(int);
    *val = i;
    L.append(val, list);
  }
  list_map(printf("%d\n", deref(L.val, int)); free(L.val);, list, tail);
  L.del(list);

  int val[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  node_t node = T.new(val), aux = NULL;

  aux = T.add(val + 1, node);
  T.add(val + 3, aux);
  T.add(val + 4, aux);
  T.add(val + 8, T.add(val + 7, T.add(val + 5, aux)));

  aux = T.add(val + 2, node);
  T.add(val + 6, aux);
  T.add(val + 9, aux);

  printf("---\n");
  tree_preorder(printf("%d(%lu) ", T.val ? deref(T.val, int) : 0, T.lvl), node);
  printf("<- inorder\n");
  printf("---\n");
  tree_postorder(printf("%d(%lu) ", T.val ? deref(T.val, int) : 0, T.lvl),
                 node);
  printf("<- postorder\n");
  printf("---\n");
  tree_breadth(printf("%d ", T.val ? (const int)deref(T.val, int) : 0), node);
  printf("<- breadth\n");
  printf("---\n");

  T.del(aux);
  tree_preorder(printf("%d(%lu) ", T.val ? deref(T.val, int) : 0, T.lvl), node);
  printf("<- inorder\n");
  T.del(node);

  slist_t sl = SL.new();
  SL.insert(val, 10, sl);
  SL.insert(val + 1, 1, sl);
  SL.insert(val + 2, 15, sl);
  SL.insert(val + 3, 10, sl);
  SL.update(val + 4, 15, sl);
  SL.insert(val + 5, 7, sl);
  SL.insert(val + 6, 7, sl);
  SL.insert(val + 7, 7, sl);
  SL.insert(val + 8, 7, sl);
  SL.insert(val + 9, 1, sl);
  SL.insert(val + 8, 1, sl);
  SL.insert(val + 7, 1, sl);
  SL.insert(val + 6, 1, sl);
  SL.insert(val + 5, 1, sl);
  SL.insert(val + 4, 1, sl);
  SL.insert(val + 3, 1, sl);

  slist_map(printf("> sl[%lu] => %d\n", SL.pos, *((int *)SL.val)), sl);

  SL.del(sl);

  return 0;
}

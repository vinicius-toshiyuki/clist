#ifndef __LIST_H__
#define __LIST_H__

#include <stdlib.h>

typedef struct elem {
  void *val;
  struct elem *next;
  struct elem *prev;
} * elem_t;

typedef struct list {
  elem_t head;
  elem_t tail;
  size_t size;
} * list_t;

struct list_controller {
  list_t (*new)();
  void (*del)();
  void (*insert)(void *, size_t, list_t);
  void (*append)(void *, list_t);
  void (*prepend)(void *, list_t);
  void *(*pop)(size_t, list_t);
  void *(*pop_head)(list_t);
  void *(*pop_tail)(list_t);
  void *(*get)(size_t, list_t);
  void *(*get_head)(list_t);
  void *(*get_tail)(list_t);
};

elem_t list_new_elem(void *val);
void list_del_elem(elem_t el);

list_t list_new_list();
void list_del_list(list_t list);

elem_t list_get_elem(size_t pos, list_t list);

void list_insert(void *val, size_t pos, list_t list);
void list_append(void *val, list_t list);
void list_prepend(void *val, list_t list);

void *list_pop(size_t pos, list_t list);
void *list_pop_head(list_t list);
void *list_pop_tail(list_t list);

void *list_get(size_t pos, list_t list);
void *list_get_head(list_t list);
void *list_get_tail(list_t list);

#define list_map(code, list)                                                   \
  {                                                                            \
    elem_t __map_el = list->head;                                              \
    void *Lval;                                                                \
    while (__map_el) {                                                         \
      Lval = __map_el->val;                                                    \
      code;                                                                    \
      __map_el = __map_el->next;                                               \
    }                                                                          \
  }

#endif

#ifndef __LIST_NO_CONTROL__
extern struct list_controller L;
#endif

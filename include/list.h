#ifndef __LIST_H__
#define __LIST_H__

#ifndef new
#define new __new
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
  void (*update)(void *, size_t, list_t);
  size_t pos;
  void *val;
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

void list_update(void *val, size_t pos, list_t list);

#define list_map(code, list, ...)                                              \
  {                                                                            \
    __VA_OPT__(                                                                \
        if (strcmp(#__VA_ARGS__, "head") && strcmp(#__VA_ARGS__, "tail")) {    \
          perror("Invalid map start\n");                                       \
          exit(EXIT_FAILURE);                                                  \
        });                                                                    \
    size_t __map_pos = L.pos;                                                  \
    void *__map_val = L.val;                                                   \
    elem_t __map_el;                                                           \
    L.pos = 0;                                                                 \
    __VA_OPT__(if (0))                                                         \
    __map_el = list->head;                                                     \
    __VA_OPT__(else __map_el = list->__VA_ARGS__;)                             \
    while (__map_el) {                                                         \
      L.val = __map_el->val;                                                   \
      { code; }                                                                \
      L.pos++;                                                                 \
      __VA_OPT__(if (0))                                                       \
      __map_el = __map_el->next;                                               \
      __VA_OPT__(else {                                                        \
        elem_t __map_el_head = __map_el->next;                                 \
        elem_t __map_el_tail = __map_el->prev;                                 \
        __map_el = __map_el_##__VA_ARGS__;                                     \
        __map_el_head = __map_el_tail; /* Remove warning */                    \
        __map_el_tail = __map_el_head; /* Remove warning */                    \
      })                                                                       \
    }                                                                          \
    L.pos = __map_pos;                                                         \
    L.val = __map_val;                                                         \
    __map_el = NULL;                                                           \
  }

#endif

#ifndef __LIST_NO_CONTROL__
extern struct list_controller L;
#endif

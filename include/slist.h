#ifndef __SLIST_H__
#define __SLIST_H__

#ifndef new
#define new __new
#endif

#include <stdio.h>

typedef struct sparse_elem {
  void *val;
  struct sparse_elem *next;
  struct sparse_elem *prev;
  size_t pos;
} * selem_t;

typedef struct sparse_list {
  selem_t head;
  selem_t tail;
  size_t size;
  size_t first;
  size_t last;
} * slist_t;

struct slist_controller {
  slist_t (*new)();
  void (*del)();
  void (*insert)(void *, size_t, slist_t);
  void (*append)(void *, slist_t);
  void (*prepend)(void *, slist_t);
  void *(*pop)(size_t, slist_t);
  void *(*pop_head)(slist_t);
  void *(*pop_tail)(slist_t);
  void *(*get)(size_t, slist_t);
  void *(*get_head)(slist_t);
  void *(*get_tail)(slist_t);
  void (*update)(void *, size_t, slist_t);
  size_t pos;
  void *val;
};

selem_t slist_new_elem(void *val, size_t pos);
void slist_del_elem(selem_t el);

selem_t slist_get_elem(size_t pos, slist_t list);

slist_t slist_new_list();
void slist_del_list(slist_t list);

void slist_insert(void *val, size_t pos, slist_t list);
void slist_append(void *val, slist_t list);
void slist_prepend(void *val, slist_t list);

void *slist_pop(size_t pos, slist_t list);
void *slist_pop_head(slist_t list);
void *slist_pop_tail(slist_t list);

void *slist_get(size_t pos, slist_t list);
void *slist_get_head(slist_t list);
void *slist_get_tail(slist_t list);

void slist_update(void *val, size_t pos, slist_t list);

#define slist_map(code, list, ...)                                             \
  {                                                                            \
    __VA_OPT__(                                                                \
        if (strcmp(#__VA_ARGS__, "head") && strcmp(#__VA_ARGS__, "tail")) {    \
          perror("Invalid map start\n");                                       \
          exit(EXIT_FAILURE);                                                  \
        });                                                                    \
    size_t __map_pos = SL.pos;                                                 \
    void *__map_val = SL.val;                                                  \
    selem_t __map_el;                                                          \
    SL.pos = 0;                                                                \
    __VA_OPT__(if (0))                                                         \
    __map_el = list->head;                                                     \
    __VA_OPT__(else __map_el = list->__VA_ARGS__;)                             \
    while (__map_el) {                                                         \
      SL.val = __map_el->val;                                                  \
      SL.pos = __map_el->pos;                                                  \
      { code; }                                                                \
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
    SL.pos = __map_pos;                                                        \
    SL.val = __map_val;                                                        \
    __map_el = NULL;                                                           \
  }

#endif

#ifndef __LIST_NO_CONTROL__
extern struct slist_controller SL;
#endif

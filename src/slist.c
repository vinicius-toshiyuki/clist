#define __LIST_NO_CONTROL__
#include <slist.h>
#undef __LIST_NO_CONTROL__
#include <stdlib.h>

struct slist_controller SL = {
    slist_new_list,
    slist_del_list,
    slist_insert,
    slist_append,
    slist_prepend,
    slist_pop,
    slist_pop_head,
    slist_pop_tail,
    slist_get,
    slist_get_head,
    slist_get_tail,
    slist_update,
    0,
    NULL,
};

selem_t slist_new_elem(void *val, size_t pos) {
  selem_t el = (selem_t)malloc(sizeof(struct sparse_elem));
  el->next = el->prev = NULL;
  el->pos = pos;
  el->val = val;
  return el;
}

void slist_del_elem(selem_t el) { free(el); }

slist_t slist_new_list() {
  slist_t list = (slist_t)malloc(sizeof(struct sparse_list));
  list->head = list->tail = NULL;
  list->first = list->last = -1;
  list->size = 0;
  return list;
}

void slist_del_list(slist_t list) {
  while (list->size > 0)
    slist_pop_head(list);
  free(list);
}

selem_t slist_get_elem(size_t pos, slist_t list) {
  if (list->size == 0) {
    perror("Can not get element from empty sparse list");
    exit(EXIT_FAILURE);
  }
  selem_t el = list->head;
  while (el && el->pos != pos)
    el = el->next;
  if (!el) {
    perror("Index not found in sparse list");
    exit(EXIT_FAILURE);
  }
  return el;
}

void slist_insert(void *val, size_t pos, slist_t list) {
  selem_t el = slist_new_elem(val, pos);
  if (list->size == 0) {
    list->head = list->tail = el;
  } else if (pos <= list->first) {
    selem_t it = list->head;
    list->head->prev = el;
    el->next = list->head;
    while (it && it->pos == it->prev->pos) {
      it->pos = it->prev->pos + 1;
      it = it->next;
    }
    list->head = el;
  } else if (pos > list->last) {
    list->tail->next = el;
    el->prev = list->tail;
    list->tail = el;
  } else {
    selem_t it = list->head;
    while (it->pos < pos)
      it = it->next;

    it->prev->next = el;
    el->prev = it->prev;
    it->prev = el;
    el->next = it;

    while (it && it->pos == it->prev->pos) {
      it->pos = it->prev->pos + 1;
      it = it->next;
    }
  }
  if (list->head)
    list->first = list->head->pos;
  if (list->tail)
    list->last = list->tail->pos;
  list->size++;
}

void slist_append(void *val, slist_t list) {
  slist_insert(val, list->last + 1, list);
}

void slist_prepend(void *val, slist_t list) {
  if (list->first > 0)
    slist_insert(val, list->first - 1, list);
  else
    slist_insert(val, list->first, list);
}

void *slist_pop(size_t pos, slist_t list) {
  selem_t el = slist_get_elem(pos, list);
  void *val = el->val;

  if (pos == list->first || pos == list->last) {
    if (pos == list->first) {
      if (list->head->next)
        list->head->next->prev = NULL;
      list->head = list->head->next;
      if (list->head)
        list->first = list->head->pos;
    }
    if (pos == list->last) {
      if (list->tail->prev)
        list->tail->prev->next = NULL;
      list->tail = list->tail->prev;
      if (list->tail)
        list->last = list->tail->pos;
    }
  } else {
    el->prev->next = el->next;
    el->next->prev = el->prev;
  }

  free(el);
  list->size--;
  return val;
}

void *slist_pop_head(slist_t list) { return slist_pop(list->first, list); }

void *slist_pop_tail(slist_t list) { return slist_pop(list->last, list); }

void *slist_get(size_t pos, slist_t list) {
  selem_t el = slist_get_elem(pos, list);
  return el->val;
}

void *slist_get_head(slist_t list) { return slist_get(list->first, list); }

void *slist_get_tail(slist_t list) { return slist_get(list->last, list); }

void slist_update(void *val, size_t pos, slist_t list) {
  selem_t el = slist_get_elem(pos, list);
  el->val = val;
}

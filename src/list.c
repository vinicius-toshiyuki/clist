#include <assert.h>
#define __LIST_NO_CONTROL__
#include <list.h>
#undef __LIST_NO_CONTROL__
#include <stdio.h>
#include <stdlib.h>

struct list_controller L = {
    list_new_list, list_del_list, list_insert,   list_append,
    list_prepend,  list_pop,      list_pop_head, list_pop_tail,
    list_get,      list_get_head, list_get_tail, 0,
    NULL,
};

elem_t list_new_elem(void *val) {
  elem_t el = (elem_t)malloc(sizeof(struct elem));
  assert(el);
  el->val = val;
  el->prev = el->next = NULL;
  return el;
}

void list_del_elem(elem_t el) { free(el); }

list_t list_new_list() {
  list_t list = (list_t)malloc(sizeof(struct list));
  assert(list);
  list->head = list->tail = NULL;
  list->size = 0;
  return list;
}

void list_del_list(list_t list) {
  while (list->size > 0) {
    list_pop(0, list);
  }
  free(list);
}

elem_t list_get_elem(size_t pos, list_t list) {
  if (!list || pos > list->size + 1) {
    perror("Invalid list or positions in list_get_elem");
    exit(EXIT_FAILURE);
  }
  elem_t el = list->head;
  for (size_t i = 0; i < pos; i++)
    el = el->next;

  return el;
}

void list_insert(void *val, size_t pos, list_t list) {
  if (!list || pos > list->size) {
    perror("Invalid list or positions in list_insert");
    exit(EXIT_FAILURE);
  }

  elem_t new_el = list_new_elem(val);
  if (list->size == 0) {
    list->head = new_el;
    list->tail = new_el;
  } else if (pos == list->size) {
    list->tail->next = new_el;
    new_el->prev = list->tail;
    list->tail = new_el;
  } else {
    elem_t el_at_pos = list_get_elem(pos, list);
    el_at_pos->prev->next = new_el;
    new_el->prev = el_at_pos->prev->next;
    el_at_pos->prev = new_el;
    new_el->next = el_at_pos;
  }
  list->size++;
}

void list_append(void *val, list_t list) { list_insert(val, list->size, list); }

void list_prepend(void *val, list_t list) { list_insert(val, 0, list); }

void *list_pop(size_t pos, list_t list) {
  if (!list || pos > list->size - 1) {
    perror("Invalid list or positions in list_pop");
    exit(EXIT_FAILURE);
  }
  elem_t el_at_pos = list_get_elem(pos, list);
  void *val = el_at_pos->val;
  if (list->size == 1) {
    list->head = list->tail = NULL;
  } else if (pos == 0) {
    el_at_pos->next->prev = NULL;
    list->head = el_at_pos->next;
  } else if (pos == list->size - 1) {
    el_at_pos->prev->next = NULL;
    list->tail = el_at_pos->prev;
  } else {
    el_at_pos->next->prev = el_at_pos->prev;
    el_at_pos->prev->next = el_at_pos->next;
  }
  list->size--;
  free(el_at_pos);
  return val;
}

void *list_pop_head(list_t list) { return list_pop(0, list); }

void *list_pop_tail(list_t list) { return list_pop(list->size - 1, list); }

void *list_get(size_t pos, list_t list) {
  elem_t el = list_get_elem(pos, list);
  return el->val;
}

void *list_get_head(list_t list) { return list_get(0, list); }

void *list_get_tail(list_t list) { return list_get(list->size, list); }

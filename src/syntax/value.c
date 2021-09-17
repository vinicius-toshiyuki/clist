#include <stdlib.h>
#include <syntax/value.h>
#include <util.h>

syn_val_t *new_syn_val(syn_type_t type, char *tag) {
  syn_val_t *val = (syn_val_t *)calloc(1, sizeof(syn_val_t));
  val->base.type = type;
  val->base.tag = tag;
  switch (type) {
  case SYN_DTYPE:
    val->dtype.depth = 0;
  default:
    break;
  }
  return val;
}

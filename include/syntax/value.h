#ifndef __SYNTAX__VALUE__
#define __SYNTAX__VALUE__

#include <util.h>

typedef enum syn_type { SYN_EXP, SYN_DTYPE, SYN_ID, SYN_DECLR } syn_type_t;

typedef enum syn_data { SYN_INT, SYN_FLOAT } syn_data_t;

typedef struct syn_base {
  syn_type_t type;
  char *tag;
} syn_base_t;

typedef struct syn_exp {
  syn_type_t type;
  char *tag;
  syn_data_t dtype;
  bool_t lval;
} syn_exp_t;

typedef syn_base_t syn_dtype_t;
typedef syn_base_t syn_id_t;
typedef syn_base_t syn_declr_t;

typedef union syn_val {
  syn_base_t base;
  syn_exp_t exp;
  syn_dtype_t type;
  syn_id_t id;
  syn_declr_t declr;
} syn_val_t;

syn_val_t *new_syn_val(syn_type_t type, char *tag);

#endif

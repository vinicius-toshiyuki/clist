#ifndef __UTIL_H__
#define __UTIL_H__

typedef enum bool_t { FALSE = 0, TRUE } bool_t;

#define alloc(type) ((type *)malloc(sizeof(type)))
#define deref(val, type) (*((type *)val))
#define as(val, type) ((type)(val))

#endif

#pragma once

#define alloc(type) ((type *)malloc(sizeof(type)))
#define deref(val, type) (*((type *)val))

#include "ruby.h"

static VALUE gleezor(VALUE self)
{
  return 1;
}

void Init_sample(void)
{
  VALUE klass = rb_define_class("Sample", rb_cObject);
  VALUE A = rb_define_module_under(klass, "A");
  VALUE B = rb_define_module_under(A, "B");

  rb_define_method(klass, "gleezor", gleezor, 0);
  rb_define_method(B, "gleezor", gleezor, 0);
  rb_define_singleton_method(B, "gleezor", gleezor, 0);
}

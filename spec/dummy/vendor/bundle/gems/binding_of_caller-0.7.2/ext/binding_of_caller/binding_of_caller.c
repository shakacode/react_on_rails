/* (c) 2011 John Mair (banisterfiend), MIT license */

#include <ruby.h>
#include "vm_core.h"
#include "rubys_gc.h"

typedef enum { false, true } bool;

static VALUE
string2sym(const char * string)
{
  return ID2SYM(rb_intern(string));
}

static inline const rb_data_type_t *
threadptr_data_type(void)
{
  static const rb_data_type_t *thread_data_type;
  if (!thread_data_type) {
    VALUE current_thread = rb_thread_current();
    thread_data_type = RTYPEDDATA_TYPE(current_thread);
  }
  return thread_data_type;
}

#define ruby_thread_data_type *threadptr_data_type()
#define ruby_threadptr_data_type *threadptr_data_type()

#define ruby_current_thread ((rb_thread_t *)RTYPEDDATA_DATA(rb_thread_current()))

static size_t
binding_memsize(const void *ptr)
{
  return ptr ? sizeof(rb_binding_t) : 0;
}

static void
binding_free(void *ptr)
{
  rb_binding_t *bind;
  RUBY_FREE_ENTER("binding");
  if (ptr) {
    bind = ptr;
    ruby_xfree(ptr);
  }
  RUBY_FREE_LEAVE("binding");
}

static void
binding_mark(void *ptr)
{
  rb_binding_t *bind;
  RUBY_MARK_ENTER("binding");
  if (ptr) {
    bind = ptr;
    RUBY_MARK_UNLESS_NULL(bind->env);

#ifdef RUBY_192
    RUBY_MARK_UNLESS_NULL(bind->filename);
#endif

  }
  RUBY_MARK_LEAVE("binding");
}

static const rb_data_type_t binding_data_type = {
  "binding",
  binding_mark,
  binding_free,
  binding_memsize,
};

static VALUE
binding_alloc(VALUE klass)
{
  VALUE obj;
  rb_binding_t *bind;
  obj = TypedData_Make_Struct(klass, rb_binding_t, &binding_data_type, bind);
  return obj;
}

static bool ifunc_p(rb_control_frame_t * cfp) {
  return (cfp->flag & VM_FRAME_MAGIC_MASK) == VM_FRAME_MAGIC_IFUNC;
}

static bool valid_frame_p(rb_control_frame_t * cfp, rb_control_frame_t * limit_cfp) {
  return cfp->iseq && !ifunc_p(cfp) && !NIL_P(cfp->self);
}

static rb_control_frame_t * find_valid_frame(rb_control_frame_t * cfp, rb_control_frame_t * limit_cfp) {
  while (cfp < limit_cfp) {
    cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);

    if (cfp >= limit_cfp)
      return NULL;

    if (valid_frame_p(cfp, limit_cfp))
      return cfp;
  }

  // beyond end of stack
  return NULL;
}

static VALUE
frametype_name(VALUE flag)
{
  switch (flag & VM_FRAME_MAGIC_MASK) {
  case VM_FRAME_MAGIC_METHOD: return string2sym("method");
  case VM_FRAME_MAGIC_BLOCK:  return string2sym("block");
  case VM_FRAME_MAGIC_CLASS:  return string2sym("class");
  case VM_FRAME_MAGIC_TOP:    return string2sym("top");
  case VM_FRAME_MAGIC_CFUNC:  return string2sym("cfunc");
  case VM_FRAME_MAGIC_PROC:   return string2sym("proc");
  case VM_FRAME_MAGIC_IFUNC:  return string2sym("ifunc");
  case VM_FRAME_MAGIC_EVAL:   return string2sym("eval");
  case VM_FRAME_MAGIC_LAMBDA: return string2sym("lambda");
  default:
    rb_raise(rb_eRuntimeError, "Unknown frame type! got flag: %d", FIX2INT(flag));
  }
}

static VALUE binding_of_caller(VALUE self, VALUE rb_level)
{
  rb_thread_t *th;
  GetThreadPtr(rb_thread_current(), th);

  rb_control_frame_t *cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th->cfp);
  rb_control_frame_t *limit_cfp = (void *)(th->stack + th->stack_size);
  int level = FIX2INT(rb_level);

  // attempt to locate the nth parent control frame
  for (int i = 0; i < level; i++) {
    cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);

    if (cfp >= limit_cfp)
      rb_raise(rb_eRuntimeError, "Invalid frame, gone beyond end of stack!");

    // skip invalid frames
    if (!valid_frame_p(cfp, limit_cfp))
      cfp = find_valid_frame(cfp, limit_cfp);
  }

  VALUE bindval = binding_alloc(rb_cBinding);
  rb_binding_t *bind;

  if (cfp == 0)
    rb_raise(rb_eRuntimeError, "Can't create Binding Object on top of Fiber.");

  GetBindingPtr(bindval, bind);

  bind->env = rb_vm_make_env_object(th, cfp);
  bind->filename = cfp->iseq->filename;
  bind->line_no = rb_vm_get_sourceline(cfp);
  
  rb_iv_set(bindval, "@frame_type", frametype_name(cfp->flag));
  rb_iv_set(bindval, "@frame_description", cfp->iseq->name);

  return bindval;
}

static VALUE
frame_type(VALUE self)
{
  return rb_iv_get(self, "@frame_type");
}

static VALUE
frame_description(VALUE self)
{
  return rb_iv_get(self, "@frame_description");
}

static VALUE frame_count(VALUE self)
{
  rb_thread_t *th;
  GetThreadPtr(rb_thread_current(), th);

  rb_control_frame_t *cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th->cfp);
  rb_control_frame_t *limit_cfp = (void *)(th->stack + th->stack_size);

  int i = 1;
  while (cfp < limit_cfp) {
    cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(cfp);

    if (cfp >= limit_cfp)
      return INT2FIX(i);

    // skip invalid frames
    if (!valid_frame_p(cfp, limit_cfp))
      cfp = find_valid_frame(cfp, limit_cfp);

    if (!cfp)
      break;

    i++;
  }

  return INT2FIX(i);
}

static VALUE
callers(VALUE self)
{
  VALUE ary = rb_ary_new();

  for (int i = 0; i < FIX2INT(frame_count(self)); i++)
    rb_ary_push(ary, binding_of_caller(self, INT2FIX(i)));

  return ary;
}

void
Init_binding_of_caller()
{
  VALUE mBindingOfCaller = rb_define_module("BindingOfCaller");

  rb_define_method(mBindingOfCaller, "of_caller", binding_of_caller, 1);
  rb_define_method(mBindingOfCaller, "frame_count", frame_count, 0);
  rb_define_method(mBindingOfCaller, "frame_type", frame_type, 0);
  rb_define_method(mBindingOfCaller, "frame_description", frame_description, 0);
  rb_define_method(mBindingOfCaller, "callers", callers, 0);
  rb_include_module(rb_cBinding, mBindingOfCaller);
}


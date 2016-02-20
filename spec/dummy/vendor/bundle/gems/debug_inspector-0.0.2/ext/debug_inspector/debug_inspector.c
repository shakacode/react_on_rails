/**********************************************************************

  debug_inspector.c

  $Author: ko1 $
  created at: Thu Nov 15 17:34:36 2012

  Copyright (C) 1993-2012 Yukihiro Matsumoto

**********************************************************************/

#include "ruby/ruby.h"

typedef struct rb_debug_inspector_struct rb_debug_inspector_t;
typedef VALUE (*rb_debug_inspector_func_t)(const rb_debug_inspector_t *, void *);

VALUE rb_debug_inspector_open(rb_debug_inspector_func_t func, void *data);
VALUE rb_debug_inspector_frame_binding_get(const rb_debug_inspector_t *dc, int index);
VALUE rb_debug_inspector_frame_class_get(const rb_debug_inspector_t *dc, int index);
VALUE rb_debug_inspector_frame_iseq_get(const rb_debug_inspector_t *dc, int index);
VALUE rb_debug_inspector_backtrace_locations(const rb_debug_inspector_t *dc);

static size_t
di_size(const void *dummy)
{
    return sizeof(void *);
}

static const rb_data_type_t di_data_type = {
    "simple_debugger",
    {0, 0, di_size,},
};

static const rb_debug_inspector_t *
di_get_dc(VALUE self)
{
    const rb_debug_inspector_t *dc;
    TypedData_Get_Struct(self, const rb_debug_inspector_t, &di_data_type, dc);
    if (dc == 0) {
	rb_raise(rb_eArgError, "invalid inspector context");
    }
    return dc;
}

static VALUE
di_backtrace_locations(VALUE self)
{
    const rb_debug_inspector_t *dc = di_get_dc(self);
    return rb_debug_inspector_backtrace_locations(dc);
}

static VALUE
di_binding(VALUE self, VALUE index)
{
    const rb_debug_inspector_t *dc = di_get_dc(self);
    return rb_debug_inspector_frame_binding_get(dc, NUM2INT(index));
}

static VALUE
di_frame_class(VALUE self, VALUE index)
{
    const rb_debug_inspector_t *dc = di_get_dc(self);
    return rb_debug_inspector_frame_class_get(dc, NUM2INT(index));
}

static VALUE
di_frame_iseq(VALUE self, VALUE index)
{
    const rb_debug_inspector_t *dc = di_get_dc(self);
    return rb_debug_inspector_frame_iseq_get(dc, NUM2INT(index));
}

static VALUE
breakpoint_i(const rb_debug_inspector_t *dc, void *ptr)
{
    VALUE self = (VALUE)ptr;
    VALUE result;

    /* should protect */
    DATA_PTR(self) = (void *)dc;
    result = rb_yield(self);
    return result;
}

static VALUE
di_open_body(VALUE self)
{
    return rb_debug_inspector_open(breakpoint_i, (void *)self);
}

static VALUE
di_open_ensure(VALUE self)
{
    DATA_PTR(self) = 0;
    return self;
}

static VALUE
di_open_s(VALUE klass)
{
    VALUE self = TypedData_Wrap_Struct(klass, &di_data_type, 0);
    return rb_ensure(di_open_body, self, di_open_ensure, self);
}

void
Init_debug_inspector(void)
{
    VALUE rb_cRubyVM = rb_const_get(rb_cObject, rb_intern("RubyVM"));
    VALUE cDebugInspector = rb_define_class_under(rb_cRubyVM, "DebugInspector", rb_cObject);
    
    rb_undef_alloc_func(cDebugInspector);
    rb_define_singleton_method(cDebugInspector, "open", di_open_s, 0);
    rb_define_method(cDebugInspector, "backtrace_locations", di_backtrace_locations, 0);
    rb_define_method(cDebugInspector, "frame_binding", di_binding, 1);
    rb_define_method(cDebugInspector, "frame_class", di_frame_class, 1);
    rb_define_method(cDebugInspector, "frame_iseq", di_frame_iseq, 1);
}

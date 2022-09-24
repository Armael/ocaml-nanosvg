#include <stdio.h>
#include <assert.h>
#include <string.h>
#define CAML_NAME_SPACE
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/bigarray.h>
#include <caml/fail.h>
#define NANOSVG_IMPLEMENTATION
#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvg.h"
#include "nanosvgrast.h"

value caml_nsvg_parse_from_file(value filename, value units, value dpi) {
  CAMLparam3(filename, units, dpi);
  CAMLlocal1(ret);
  NSVGimage* image = nsvgParseFromFile(String_val(filename), String_val(units), (float)Double_val(dpi));
  if (image) {
    assert (((uintptr_t) image & 1) == 0);
    ret = caml_alloc_some((value) image | 1);
  } else {
    ret = Val_none;
  }
  CAMLreturn(ret);
}

value caml_nsvg_parse(value data, value units, value dpi) {
  CAMLparam3(data, units, dpi);
  CAMLlocal1(ret);
  char* data_s = strdup(String_val(data));
  NSVGimage* image = nsvgParse(data_s, String_val(units), (float)Double_val(dpi));
  if (image) {
    assert (((uintptr_t) image & 1) == 0);
    ret = caml_alloc_some((value) image | 1);
  } else {
    ret = Val_none;
  }
  CAMLreturn(ret);
}

value caml_nsvg_delete(value image) {
  nsvgDelete((NSVGimage*) (image & ~1));
}

// NSVGimage accessors

value caml_nsvg_image_width(value image) {
  CAMLparam1(image);
  CAMLlocal1(ret);
  NSVGimage* image_p = (NSVGimage*) (image & ~1);
  ret = caml_copy_double((double)image_p->width);
  CAMLreturn(ret);
}

value caml_nsvg_image_height(value image) {
  CAMLparam1(image);
  CAMLlocal1(ret);
  NSVGimage* image_p = (NSVGimage*) (image & ~1);
  ret = caml_copy_double((double)image_p->height);
  CAMLreturn(ret);
}

value caml_nsvg_image_shapes(value image) {
  CAMLparam1(image);
  CAMLlocal1(list);
  list = Val_int(0);
  value* cur = &list;
  NSVGimage* image_p = (NSVGimage*) (image & ~1);
  NSVGshape* shape = image_p->shapes;
  while (shape) {
    assert (((uintptr_t) shape & 1) == 0);
    *cur = caml_alloc_tuple(2);
    Field(*cur, 0) = ((value) shape | 1);
    Field(*cur, 1) = Val_int(0);
    cur = &Field(*cur, 1);
    shape = shape->next;
  }
  CAMLreturn(list);
}

// NSVGpaint

value caml_nsvg_paint(NSVGpaint* paint) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  switch(paint->type) {
    case NSVG_PAINT_NONE:
      ret = Val_int(0);
      break;
    case NSVG_PAINT_COLOR:
      ret = caml_alloc(1, 1);
      tmp = caml_copy_int32(paint->color);
      Field(ret, 0) = tmp;
      break;
    case NSVG_PAINT_LINEAR_GRADIENT:
      ret = caml_alloc(1, 2);
      assert (((uintptr_t) paint->gradient & 1) == 0);
      tmp = (value) paint->gradient | 1;
      Field(ret, 0) = tmp;
      break;
    case NSVG_PAINT_RADIAL_GRADIENT:
      ret = caml_alloc(1, 3);
      assert (((uintptr_t) paint->gradient & 1) == 0);
      tmp = (value) paint->gradient | 1;
      Field(ret, 0) = tmp;
      break;
    default: // impossible
      ret = Val_int(0);
      break;
  }
  CAMLreturn(ret);
}
// NSVGshape accessors

value caml_nsvg_shape_opacity(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_copy_double((double)shape_p->opacity);
  CAMLreturn(ret);
}

value caml_nsvg_shape_stroke_width(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_copy_double((double)shape_p->strokeWidth);
  CAMLreturn(ret);
}

value caml_nsvg_shape_stroke_dash_offset(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_copy_double((double)shape_p->strokeDashOffset);
  CAMLreturn(ret);
}

// TODO: strokeDashArray

value caml_nsvg_shape_stroke_dash_count(value shape) {
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  return Val_int(shape_p->strokeDashCount);
}

value caml_nsvg_shape_stroke_line_join(value shape) {
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  return Val_int(shape_p->strokeLineJoin);
}

value caml_nsvg_shape_stroke_line_cap(value shape) {
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  return Val_int(shape_p->strokeLineCap);
}

value caml_nsvg_shape_miter_limit(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_copy_double((double)shape_p->miterLimit);
  CAMLreturn(ret);
}

value caml_nsvg_shape_fill_rule(value shape) {
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  return Val_int(shape_p->fillRule);
}

value caml_nsvg_shape_fill(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_nsvg_paint(&shape_p->fill);
  CAMLreturn(ret);
}

value caml_nsvg_shape_stroke(value shape) {
  CAMLparam1(shape);
  CAMLlocal1(ret);
  NSVGshape* shape_p = (NSVGshape*) (shape & ~1);
  ret = caml_nsvg_paint(&shape_p->stroke);
  CAMLreturn(ret);
}

// Rasterize

value caml_nsvg_create_rasterizer(value unit) {
  NSVGrasterizer* rast = nsvgCreateRasterizer();
  assert (rast);
  assert (((uintptr_t) rast & 1) == 0);
  return (value) rast | 1;
}

value caml_nsvg_delete_rasterizer(value rast) {
  NSVGrasterizer* rast_p = (NSVGrasterizer*) (rast & ~1);
  nsvgDeleteRasterizer(rast_p);
  return Val_unit;
}

value caml_nsvg_rasterize_native(value rast, value image,
                                 value tx, value ty, value scale,
                                 value dst, value w, value h, value stride) {
  NSVGrasterizer* rast_p = (NSVGrasterizer*) (rast & ~1);
  NSVGimage* image_p = (NSVGimage*) (image & ~1);
  nsvgRasterize(rast_p, image_p,
                (float)Double_val(tx), (float)Double_val(ty), (float)Double_val(scale),
                (unsigned char*)Caml_ba_data_val(dst),
                Int_val(w), Int_val(h), Int_val(stride));
}

value caml_nsvg_rasterize_bytecode(value* argv, int argn) {
  return caml_nsvg_rasterize_native(argv[0], argv[1], argv[2], argv[3], argv[4],
                                    argv[5], argv[6], argv[7], argv[8]);
}

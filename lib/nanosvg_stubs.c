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

// NSVGgradient

value caml_nsvg_alloc_gradient(NSVGgradient* g) {
  CAMLparam0();
  CAMLlocal1(ret);
  ret = Val_int(0); // TODO
  CAMLreturn(ret);
}

// NSVGpaint

value caml_nsvg_alloc_paint(NSVGpaint* paint) {
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
      tmp = caml_nsvg_alloc_gradient(paint->gradient);
      Field(ret, 0) = tmp;
      break;
    case NSVG_PAINT_RADIAL_GRADIENT:
      ret = caml_alloc(1, 3);
      tmp = caml_nsvg_alloc_gradient(paint->gradient);
      Field(ret, 0) = tmp;
      break;
    default: // impossible
      ret = Val_int(0);
      break;
  }
  CAMLreturn(ret);
}

// NSVGshape

value caml_nsvg_alloc_shape(NSVGshape* shape) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  ret = caml_alloc(10, 0);
  int field = 0;
  // TODO: id
  // fill
  tmp = caml_nsvg_alloc_paint(&shape->fill);
  Field(ret, field++) = tmp;
  // stroke
  tmp = caml_nsvg_alloc_paint(&shape->stroke);
  Field(ret, field++) = tmp;
  // opacity
  tmp = caml_copy_double(shape->opacity);
  Field(ret, field++) = tmp;
  // stroke_width
  tmp = caml_copy_double(shape->strokeWidth);
  Field(ret, field++) = tmp;
  // stroke_dash_offset
  tmp = caml_copy_double(shape->strokeDashOffset);
  Field(ret, field++) = tmp;
  // TODO: strokeDashArray
  // stroke_dash_count
  tmp = Val_int(shape->strokeDashCount);
  Field(ret, field++) = tmp;
  // stroke_line_join
  tmp = Val_int(shape->strokeLineJoin);
  Field(ret, field++) = tmp;
  // stroke_line_cap
  tmp = Val_int(shape->strokeLineCap);
  Field(ret, field++) = tmp;
  // miter_limit
  tmp = caml_copy_double(shape->miterLimit);
  Field(ret, field++) = tmp;
  // fill_rule
  tmp = Val_int(shape->fillRule);
  Field(ret, field++) = tmp;
  // TODO: flags, bounds, paths
  CAMLreturn(ret);
}

// NSVGimage

value caml_nsvg_alloc_image(NSVGimage* image) {
  CAMLparam0();
  CAMLlocal3(ret, tmp, list);
  ret = caml_alloc(3, 0);
  // width
  tmp = caml_copy_double(image->width);
  Field(ret, 0) = tmp;
  // height
  tmp = caml_copy_double(image->height);
  Field(ret, 1) = tmp;
  // shapes
  list = Val_int(0);
  value* cur = &list;
  NSVGshape* shape = image->shapes;
  while (shape) {
    *cur = caml_alloc_tuple(2);
    tmp = caml_nsvg_alloc_shape(shape);
    Field(*cur, 0) = tmp;
    Field(*cur, 1) = Val_int(0);
    cur = &Field(*cur, 1);
    shape = shape->next;
  }
  Field(ret, 2) = list;
  CAMLreturn(ret);
}

value caml_nsvg_delete_image_c_data(value c_data) {
  nsvgDelete((NSVGimage*) (c_data & ~1));
  return Val_unit;
}

// NSVGImage width/height accessors

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

// lift

value caml_nsvg_lift(value c_data) {
  CAMLparam1(c_data);
  CAMLlocal1(ret);
  NSVGimage* image = (NSVGimage*) (c_data & ~1);
  ret = caml_nsvg_alloc_image(image);
  CAMLreturn(ret);
}

// parsing

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

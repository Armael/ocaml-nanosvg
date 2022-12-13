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

// NSVGtextAnchor

value caml_nsvg_text_anchor(enum NSVGtextAnchor anchor) {
  // NSVGtextAnchor seems to be a bitfield, but I'm not sure it makes sense to
  // have several anchors at the same time?
  // Let's ignore the bitfield aspect and handle only one for now.
  value text_anchor = Val_int(0); // Anchor_left is the default
  if (anchor & NSVG_ANCHOR_CENTER)
    text_anchor = Val_int(1);
  if (anchor & NSVG_ANCHOR_RIGHT)
    text_anchor = Val_int(2);
  return text_anchor;
}

// NSVGtextStyle

value caml_nsvg_text_style(enum NSVGtextStyle style) {
  // same considerations than for NSVGtextAnchor
  value text_style = Val_int(0); // Text_normal is the default
  if (style & NSVG_TEXT_ITALIC)
    text_style = Val_int(1);
  if (style & NSVG_TEXT_OBLIQUE)
    text_style = Val_int(2);
  return text_style;
}

// NSVGgradientStop

value caml_nsvg_alloc_gradient_stop(NSVGgradientStop* gs) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  ret = caml_alloc(2, 0);
  // color
  tmp = caml_copy_int32(gs->color);
  Store_field(ret, 0, tmp);
  // offset
  tmp = caml_copy_double(gs->offset);
  Store_field(ret, 1, tmp);
  CAMLreturn(ret);
}

// NSVGgradient

value caml_nsvg_alloc_gradient(NSVGgradient* g) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  ret = caml_alloc(5, 0); // gradient
  int field = 0;
  // xform
  tmp = caml_alloc_float_array(6);
  for (int i = 0; i < 6; i++) {
    Store_double_array_field(tmp, i, (double)g->xform[i]);
  }
  Store_field(ret, field++, tmp);
  // spread
  Store_field(ret, field++, Val_int(g->spread));
  // fx
  tmp = caml_copy_double(g->fx);
  Store_field(ret, field++, tmp);
  // fy
  tmp = caml_copy_double(g->fy);
  Store_field(ret, field++, tmp);
  // stops
  tmp = caml_alloc(g->nstops, 0);
  for (int i = 0; i < g->nstops; i++) {
    Store_field(tmp, i, caml_nsvg_alloc_gradient_stop(&g->stops[i]));
  }
  Store_field(ret, field++, tmp);
  CAMLreturn(ret);
}

// NSVGpaint

value caml_nsvg_alloc_paint(NSVGpaint* paint) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  switch(paint->type) {
    case NSVG_PAINT_NONE:
      ret = Val_int(0); // Paint_none
      break;
    case NSVG_PAINT_COLOR:
      ret = caml_alloc(1, 0); // Paint_color
      tmp = caml_copy_int32(paint->color);
      Store_field(ret, 0, tmp);
      break;
    case NSVG_PAINT_LINEAR_GRADIENT:
      ret = caml_alloc(1, 1); // Paint_linear_gradient
      tmp = caml_nsvg_alloc_gradient(paint->gradient);
      Store_field(ret, 0, tmp);
      break;
    case NSVG_PAINT_RADIAL_GRADIENT:
      ret = caml_alloc(1, 2); // Paint_radial_gradient
      tmp = caml_nsvg_alloc_gradient(paint->gradient);
      Store_field(ret, 0, tmp);
      break;
    default: // impossible
      ret = Val_int(0);
      break;
  }
  CAMLreturn(ret);
}

// bounding box

value caml_nsvg_alloc_bounds(float* bounds) {
  CAMLparam0();
  CAMLlocal1(ret);
  ret = caml_alloc_float_array(4); // box
  for (int i = 0; i < 4; i++) {
    Store_double_array_field(ret, i, (double)bounds[i]);
  }
  CAMLreturn(ret);
}

// point

value caml_nsvg_alloc_point(float* pt) {
  CAMLparam0();
  CAMLlocal1(ret);
  ret = caml_alloc_float_array(2); // point
  Store_double_array_field(ret, 0, (double)pt[0]);
  Store_double_array_field(ret, 1, (double)pt[1]);
  CAMLreturn(ret);
}

// NSVGpath

value caml_nsvg_alloc_path(NSVGpath* path) {
  CAMLparam0();
  CAMLlocal3(ret, tmp, tmp2);
  ret = caml_alloc(3, 0); // path
  int field = 0;
  // points
  tmp = caml_alloc(path->npts, 0); // path.points
  for (int i = 0; i < path->npts; i++) {
    tmp2 = caml_nsvg_alloc_point(&path->pts[i*2]);
    Store_field(tmp, i, tmp2);
  }
  Store_field(ret, field++, tmp);
  // closed
  tmp = Val_int(path->closed ? 1 : 0);
  Store_field(ret, field++, tmp);
  // bounds
  tmp = caml_nsvg_alloc_bounds(path->bounds);
  Store_field(ret, field++, tmp);
  assert (Field(ret, 0) != ret);
  CAMLreturn(ret);
}

// NSVGtext

value caml_nsvg_alloc_text(NSVGtext* text) {
  CAMLparam0();
  CAMLlocal2(ret, tmp);
  ret = caml_alloc(6, 0); // text
  int field = 0;
  // xform
  tmp = caml_alloc_float_array(6); // text.xform
  for (int i = 0; i < 6; i++) {
    Store_double_array_field(tmp, i, (double)text->xform[i]);
  }
  Store_field(ret, field++, tmp);
  // anchor
  tmp = caml_nsvg_text_anchor(text->anchor);
  Store_field(ret, field++, tmp);
  // style
  tmp = caml_nsvg_text_style(text->style);
  Store_field(ret, field++, tmp);
  // fontsize
  tmp = caml_copy_double(text->fontsize);
  Store_field(ret, field++, tmp);
  // fontfamily
  tmp = caml_copy_string(text->fontfamily);
  Store_field(ret, field++, tmp);
  // s
  tmp = caml_copy_string(text->s);
  Store_field(ret, field++, tmp);
  CAMLreturn(ret);
}

// NSVGshape

value caml_nsvg_alloc_shape(NSVGshape* shape) {
  CAMLparam0();
  CAMLlocal3(ret, tmp, list);
  ret = caml_alloc(14, 0); // shape
  int field = 0;
  // id
  char* id_tmp = calloc(65, sizeof(char));
  strncpy(id_tmp, shape->id, 64);
  tmp = caml_copy_string(id_tmp);
  free(id_tmp);
  Store_field(ret, field++, tmp);
  // fill
  tmp = caml_nsvg_alloc_paint(&shape->fill);
  Store_field(ret, field++, tmp);
  // stroke
  tmp = caml_nsvg_alloc_paint(&shape->stroke);
  Store_field(ret, field++, tmp);
  // opacity
  tmp = caml_copy_double(shape->opacity);
  Store_field(ret, field++, tmp);
  // stroke_width
  tmp = caml_copy_double(shape->strokeWidth);
  Store_field(ret, field++, tmp);
  // stroke_dash_offset
  tmp = caml_copy_double(shape->strokeDashOffset);
  Store_field(ret, field++, tmp);
  // stroke_dash_array
  tmp = caml_alloc_float_array(shape->strokeDashCount);
  for (int i = 0; i < shape->strokeDashCount; i++) {
    Store_double_array_field(tmp, i, (double)shape->strokeDashArray[i]);
  }
  Store_field(ret, field++, tmp);
  // stroke_line_join
  tmp = Val_int(shape->strokeLineJoin);
  Store_field(ret, field++, tmp);
  // stroke_line_cap
  tmp = Val_int(shape->strokeLineCap);
  Store_field(ret, field++, tmp);
  // stroke_align
  tmp = Val_int(shape->strokeAlign);
  Store_field(ret, field++, tmp);
  // miter_limit
  tmp = caml_copy_double(shape->miterLimit);
  Store_field(ret, field++, tmp);
  // fill_rule
  tmp = Val_int(shape->fillRule);
  Store_field(ret, field++, tmp);
  // flags (only one: NSVG_FLAGS_VISIBLE)
  tmp = Val_int(shape->flags ? 1 : 0); // visible?
  Store_field(ret, field++, tmp);
  // bounds
  tmp = caml_nsvg_alloc_bounds(shape->bounds);
  Store_field(ret, field++, tmp);
  // payload
  if (shape->paths) {
    assert(shape->text == NULL);
    list = Val_int(0);
    value* cur = &list;
    NSVGpath* path = shape->paths;
    while (path) {
      *cur = caml_alloc_tuple(2); // (::)
      tmp = caml_nsvg_alloc_path(path);
      Store_field(*cur, 0, tmp);
      Store_field(*cur, 1, Val_int(0));
      cur = &Field(*cur, 1);
      path = path->next;
    }
    tmp = caml_alloc(1, 0); // Shape_paths(_)
    Store_field(tmp, 0, list);
  } else {
    assert(shape->text != NULL);
    assert(shape->paths == NULL);
    list/*not actually a list*/ = caml_nsvg_alloc_text(shape->text);
    tmp = caml_alloc(1, 1); // Shape_text(_)
    Store_field(tmp, 0, list);
  }
  Store_field(ret, field++, tmp);
  CAMLreturn(ret);
}

// NSVGimage

value caml_nsvg_alloc_image(NSVGimage* image) {
  CAMLparam0();
  CAMLlocal3(ret, tmp, list);
  ret = caml_alloc(4, 0); // image
  int field = 0;
  // width
  tmp = caml_copy_double(image->width);
  Store_field(ret, field++, tmp);
  // height
  tmp = caml_copy_double(image->height);
  Store_field(ret, field++, tmp);
  // viewXform
  tmp = caml_alloc_float_array(6);
  for (int i = 0; i < 6; i++)
    Store_double_array_field(tmp, i, (double)image->viewXform[i]);
  Store_field(ret, field++, tmp);
  // shapes
  list = Val_int(0);
  value* cur = &list;
  NSVGshape* shape = image->shapes;
  while (shape) {
    *cur = caml_alloc_tuple(2); // (::)
    tmp = caml_nsvg_alloc_shape(shape);
    Store_field(*cur, 0, tmp);
    Store_field(*cur, 1, Val_int(0));
    cur = &Field(*cur, 1);
    shape = shape->next;
  }
  Store_field(ret, field++, list);
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

value caml_nsvg_image_viewXform(value image) {
  CAMLparam1(image);
  CAMLlocal1(ret);
  NSVGimage* image_p = (NSVGimage*) (image & ~1);
  ret = caml_alloc_float_array(6);
  for (int i = 0; i < 6; i++)
    Store_double_array_field(ret, i, (double)image_p->viewXform[i]);
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

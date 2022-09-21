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

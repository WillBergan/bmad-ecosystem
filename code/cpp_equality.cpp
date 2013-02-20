
//+
// C++ equality functions for Bmad / C++ structure interface.
//
// This file is generated as part of the Bmad/C++ interface code generation.
// The code generation files can be found in cpp_bmad_interface.
//
// DO NOT EDIT THIS FILE DIRECTLY! 
//-

#include <iostream>
#include <stdlib.h>
#include "cpp_bmad_classes.h"

using namespace std;

//---------------------------------------------------

template <class T> bool is_all_equal (const valarray<T>& vec1, const valarray<T>& vec2) {
  bool is_eq = true;
  if (vec1.size() != vec2.size()) return false;
  for (unsigned int i = 0; i < vec1.size(); i++) {
    is_eq = is_eq && (vec1[i] == vec2[i]);
  }
  return is_eq;
}

template <class T> bool is_all_equal (const valarray< valarray<T> >& mat1, const valarray< valarray<T> >& mat2) {
  bool is_eq = true;
  if (mat1.size() != mat2.size()) return false;
  for (unsigned int i = 0; i < mat1.size(); i++) {
    if (mat1[i].size() != mat2[i].size()) return false;
    for (unsigned int j = 0; j < mat1[i].size(); j++) {
      is_eq = is_eq && (mat1[i][j] == mat2[i][j]);
    }
  }
  return is_eq;
};

template <class T> bool is_all_equal (const valarray< valarray< valarray<T> > >& tensor1, const valarray< valarray< valarray<T> > >& tensor2) {
  bool is_eq = true;
  if (tensor1.size() != tensor2.size()) return false;
  for (unsigned int i = 0; i < tensor1.size(); i++) {
    if (tensor1[i].size() != tensor2[i].size()) return false;
    for (unsigned int j = 0; j < tensor1[i].size(); j++) {
      if (tensor1[i][j].size() != tensor2[i][j].size()) return false;
      for (unsigned int k = 0; k < tensor1[i][j].size(); k++) {
        is_eq = is_eq && (tensor1[i][j][k] == tensor2[i][j][k]);
      }
    }
  }
  return is_eq;
};

//---------------------------------------------------

template bool is_all_equal (const Bool_ARRAY&,     const Bool_ARRAY&);
template bool is_all_equal (const Complex_ARRAY&,  const Complex_ARRAY&);
template bool is_all_equal (const Real_ARRAY&,     const Real_ARRAY&);
template bool is_all_equal (const Int_ARRAY&,      const Int_ARRAY&);
template bool is_all_equal (const String_ARRAY&,   const String_ARRAY&);

template bool is_all_equal (const Bool_MATRIX&,     const Bool_MATRIX&);
template bool is_all_equal (const Complex_MATRIX&,  const Complex_MATRIX&);
template bool is_all_equal (const Real_MATRIX&,     const Real_MATRIX&);
template bool is_all_equal (const Int_MATRIX&,      const Int_MATRIX&);

template bool is_all_equal (const Complex_TENSOR&,  const Complex_TENSOR&);
template bool is_all_equal (const Real_TENSOR&,     const Real_TENSOR&);
template bool is_all_equal (const Int_TENSOR&,      const Int_TENSOR&);


//--------------------------------------------------------------

bool operator== (const CPP_my& x, const CPP_my& y) {
  bool is_eq = true;
  is_eq = is_eq && (x.a == y.a);
  return is_eq;
};

template bool is_all_equal (const CPP_my_ARRAY&, const CPP_my_ARRAY&);
template bool is_all_equal (const CPP_my_MATRIX&, const CPP_my_MATRIX&);

//--------------------------------------------------------------

bool operator== (const CPP_ttt& x, const CPP_ttt& y) {
  bool is_eq = true;
  is_eq = is_eq && (x.i0 == y.i0);
  is_eq = is_eq && ((x.ip0 == NULL) == (y.ip0 == NULL));
  if (!is_eq) return false;
  if (x.ip0 != NULL) is_eq = (*x.ip0 == *y.ip0);
  is_eq = is_eq && ((x.ia0 == NULL) == (y.ia0 == NULL));
  if (!is_eq) return false;
  if (x.ia0 != NULL) is_eq = (*x.ia0 == *y.ia0);
  is_eq = is_eq && is_all_equal(x.i1, y.i1);
  is_eq = is_eq && is_all_equal(x.ip1, y.ip1);
  is_eq = is_eq && is_all_equal(x.ia1, y.ia1);
  is_eq = is_eq && is_all_equal(x.i2, y.i2);
  is_eq = is_eq && is_all_equal(x.ip2, y.ip2);
  is_eq = is_eq && is_all_equal(x.ia2, y.ia2);
  is_eq = is_eq && is_all_equal(x.i3, y.i3);
  is_eq = is_eq && is_all_equal(x.ip3, y.ip3);
  is_eq = is_eq && is_all_equal(x.ia3, y.ia3);
  return is_eq;
};

template bool is_all_equal (const CPP_ttt_ARRAY&, const CPP_ttt_ARRAY&);
template bool is_all_equal (const CPP_ttt_MATRIX&, const CPP_ttt_MATRIX&);

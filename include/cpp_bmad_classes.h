
//+
// C++ classes definitions for Bmad / C++ structure interface.
//
// This file is generated as part of the Bmad/C++ interface code generation.
// The code generation files can be found in cpp_bmad_interface.
//
// DO NOT EDIT THIS FILE DIRECTLY! 
//-

#ifndef CPP_BMAD_CLASSES

#include <string>
#include <string.h>
#include <valarray>
#include <complex>
#include "bmad_enums.h"

using namespace std;

typedef bool               Bool;
typedef complex<double>    Complex;
typedef double             Real;
typedef int                Int;
typedef char*              Char;

typedef const bool               c_Bool;
typedef const Complex            c_Complex;
typedef const double             c_Real;
typedef const int                c_Int;
typedef const string             c_String;
typedef const char*              c_Char;

typedef const bool*              c_BoolArr;
typedef const Complex*           c_ComplexArr;
typedef const double*            c_RealArr;
typedef const int*               c_IntArr;

typedef valarray<bool>           Bool_ARRAY;
typedef valarray<Complex>        Complex_ARRAY;
typedef valarray<double>         Real_ARRAY;
typedef valarray<int>            Int_ARRAY;
typedef valarray<string>         String_ARRAY;

typedef valarray<Bool_ARRAY>     Bool_MATRIX;
typedef valarray<Complex_ARRAY>  Complex_MATRIX;
typedef valarray<Real_ARRAY>     Real_MATRIX;
typedef valarray<Int_ARRAY>      Int_MATRIX;

typedef valarray<Bool_MATRIX>      Bool_TENSOR;
typedef valarray<Complex_MATRIX>   Complex_TENSOR;
typedef valarray<Real_MATRIX>      Real_TENSOR;
typedef valarray<Int_MATRIX>       Int_TENSOR;


class CPP_my;
typedef valarray<CPP_my>          CPP_my_ARRAY;
typedef valarray<CPP_my_ARRAY>    CPP_my_MATRIX;
typedef valarray<CPP_my_MATRIX>   CPP_my_TENSOR;

class CPP_ttt;
typedef valarray<CPP_ttt>          CPP_ttt_ARRAY;
typedef valarray<CPP_ttt_ARRAY>    CPP_ttt_MATRIX;
typedef valarray<CPP_ttt_MATRIX>   CPP_ttt_TENSOR;

//--------------------------------------------------------------------
// CPP_my

class Bmad_my_class {};  // Opaque class for pointers to corresponding fortran structs.

class CPP_my {
public:
  Int a;

  CPP_my() :
    a(0)
    {}

  ~CPP_my() {
  }

};   // End Class

extern "C" void my_to_c (const Bmad_my_class*, CPP_my&);
extern "C" void my_to_f (const CPP_my&, Bmad_my_class*);

bool operator== (const CPP_my&, const CPP_my&);


//--------------------------------------------------------------------
// CPP_ttt

class Bmad_ttt_class {};  // Opaque class for pointers to corresponding fortran structs.

class CPP_ttt {
public:
  Bool i0;
  Bool* ip0;
  Bool* ia0;
  Bool_ARRAY i1;
  Bool_ARRAY ip1;
  Bool_ARRAY ia1;
  Bool_MATRIX i2;
  Bool_MATRIX ip2;
  Bool_MATRIX ia2;
  Bool_TENSOR i3;
  Bool_TENSOR ip3;
  Bool_TENSOR ia3;

  CPP_ttt() :
    i0(false),
    ip0(NULL),
    ia0(NULL),
    i1(false, 3),
    ip1(false, 0),
    ia1(false, 0),
    i2(Bool_ARRAY(false, 2), 3),
    ip2(Bool_ARRAY(false, 0), 0),
    ia2(Bool_ARRAY(false, 0), 0),
    i3(Bool_MATRIX(Bool_ARRAY(false, 1), 2), 3),
    ip3(Bool_MATRIX(Bool_ARRAY(false, 0), 0), 0),
    ia3(Bool_MATRIX(Bool_ARRAY(false, 0), 0), 0)
    {}

  ~CPP_ttt() {
    delete ip0;
    delete ia0;
  }

};   // End Class

extern "C" void ttt_to_c (const Bmad_ttt_class*, CPP_ttt&);
extern "C" void ttt_to_f (const CPP_ttt&, Bmad_ttt_class*);

bool operator== (const CPP_ttt&, const CPP_ttt&);


//--------------------------------------------------------------------

#define CPP_BMAD_CLASSES
#endif

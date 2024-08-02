#!/usr/bin/env python3

# Note: 
#   Run this script in the cpp_bmad_interface directory.
#   This script searches a set of Bmad files and generates corresponding constants for use with C++ code.
#   The constants file is: include/bmad_enums.h
#   For example, the proton$ parameter on the Fortran side is translated to PROTON on the C++ side.

import re
import os

def searchit (file):

  re_int  = re.compile('INTEGER, *PARAMETER *:: *')
  re_real = re.compile('REAL\(RP\), *PARAMETER *:: *')
  re_a = re.compile('\[')
  re_d_exp = re.compile('\dD[+-]?\d')
  re_equal = re.compile('\=.*\dD[+-]?\d')

  params_here = False

  f_in = open(file)
  for line in f_in:
    line = line.partition('!')[0].rstrip()   # Strip off comment
    line = line.upper()
    if '[' in line: continue                              # Skip parameter arrays

    if not re_int.match(line) and not re_real.match(line) and not params_here: continue

    line = re_int.sub('const int ', line)
    line = re_real.sub('const double ', line)

    if '(' in line: continue                              # Skip parameter arrays. EG: "real(rp), parameter :: abc(3) = 0"

    line = line.replace('$', '')

    if "Z'" in line:
      line = line.replace("Z'", '0x')
      line = line.replace("'", '')

    if "z'" in line:
      line = line.replace("z'", '0x')
      line = line.replace("'", '')

    if re_equal.search(line):
      sub = re_d_exp.search(line).group(0).replace('D', 'E')   # Replace "3D6" with "3E6"
      line = re_d_exp.sub(sub, line)

    if '_RP' == line[-3:]: line = line[:-3]

    if '&' in line:
      line = line.replace('&', '')
      params_here = True
      line = '  ' + line + '\n'
    else:
      params_here = False
      line = '  ' + line + ';\n'

    f_out.write(line)

#---------------------------------------

if not os.path.exists('include'): os.makedirs('include')
f_out = open('include/bmad_enums.h', 'w')

f_out.write('''
//+
// C++ constants equivalent to Bmad parameters.
//
// This file is generated as part of the Bmad/C++ interface code generation.
// The code generation files can be found in cpp_bmad_interface.
//
// DO NOT EDIT THIS FILE DIRECTLY! 
//-

#ifndef BMAD_ENUMS

// The TRUE/FALSE stuff is to get around a problem with TRUE and FALSE being defined using #define

#ifdef TRUE
#undef TRUE
#define TRUE_DEF
#endif

#ifdef FALSE
#undef FALSE
#define FALSE_DEF
#endif

namespace Bmad {
''')

searchit('../bmad/modules/bmad_struct.f90')
searchit('../sim_utils/io/output_mod.f90')
searchit('../sim_utils/interfaces/physical_constants.f90')
searchit('../sim_utils/interfaces/particle_species_mod.f90')
searchit('../sim_utils/interfaces/sim_utils_struct.f90')
searchit('../sim_utils/plot/quick_plot_struct.f90')

f_out.write('''
}

#ifdef TRUE_DEF
#define TRUE    1
#undef TRUE_DEF
#endif

#ifdef FALSE_DEF
#define FALSE   0
#undef FALSE_DEF
#endif

#define BMAD_ENUMS
#endif
''')

print('Created: include/bmad_enums.h')


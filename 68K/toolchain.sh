#!/bin/bash

BASE="$HOME/amigatools"

# Build using vasm and NDK
#
function amiBuildN() {
  # $1 = binary name and source code have the same name
	
  # note: -kick1hunks should be used for kickstarter 1.x otherwise remove
  ${BASE}/toolchain/vasm/vasmm68k_mot -kick1hunks -Fhunkexe -I${BASE}/NDK_3.1/Include_Libs/include_i -o ${1/.asm/} -nosym $1

}

# Build using just vasm
#
function amiBuild() {
  # $1 = binary name and source code have the same name

	# note: -kick1hunks should be used for kickstarter 1.x otherwise remove
  ${BASE}/toolchain/vasm/vasmm68k_mot -kick1hunks -Fhunkexe -I${BASE}/NDK_3.1/Include_Libs/include_i -o ${1/.asm/} -nosym $1
}

# Output name is different than source name
#
function amiBuild2() {
	# $1 = binary name to set
	# $2 = source code to compile with ext
	# note: -kick1hunks should be added for kickstarter 1.x
	${BASE}/toolchain/vasm/vasmm68k_mot -kick1hunks -Fhunkexe -I${BASE}/NDK_3.1/Include_Libs/include_i -o ${1/.asm/} -nosym $2
}

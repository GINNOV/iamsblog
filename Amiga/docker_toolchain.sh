#!/bin/bash

BASE="$HOME/amigatools"

# AMIGA TOOLCHAIN
#

#####################################################
############# START DOCKER ##########################
#####################################################

function d_amigcc() {
	# if [[ ! -f "$1"  && ( ! -d "$1" || ! -f "$1/$2" ) ]]; then
	#     echo "$1 not found"
	#     echo "$2 not found"
	#     echo "Usage: $0 [executable folder] <amiga executable>"
	#     return
	# fi
	
	# $1 = folder
	# $2 = source code to compile without ext
	docker run -v $PWD/"$1":/opt/folder -it sebastianbergmann/m68k-amigaos-bebbo m68k-amigaos-gcc opt/folder/"$2".c -o opt/folder/"$2" -noixemul
}

function d_amirun() {
	# $1 = folder
	# $2 = exectable to run
	docker run -v $PWD/"$1":/opt/folder sebastianbergmann/amitools:latest vamos -C 68020 opt/folder/"$2"
}

function d_amivasm() {
	# $1 = folder
	# $2 = source code to compile without ext
	# $3 = exectable name
	docker run -v $PWD/"$1":/opt/folder sebastianbergmann/m68k-amigaos-bebbo vasm -Fhunkexe -o opt/folder/"$3" opt/folder/"$2".s
}

###################################################
############# END DOCKER ##########################
###################################################

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

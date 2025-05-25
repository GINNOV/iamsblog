#!/bin/bash

# STEP ONE -execute a command and catch its output

# they are backward quotes
output=`ls .`

stringToSearch="json"

# grep the output for the selected word(s)
ret=` grep $stringToSearch <<< "$output" ` # the spaces are crucials

if [ "$ret" == $stringToSearch ]; then
	PURPLE='\033[0;35m'
	NC='\033[0m' # No Color
	echo -e "${PURPLE} FOUND IT! ${NC}\n"
  # execute here something nice :-)
fi

#!/bin/bash
# Highlights EDB-IDs of not verified exploits in the searchsploit output. Also excludes exploits in path /dos/
# Author: https://github.com/wandt0n
# Usage: As you would use searchsploit (./searchsploit_custom.sh <flags> <searchterm>)
# Optional installation: Put the following line in ~/.bashrc: alias searchsploit="<pathToScript>/searchsploit_custom.sh"

pycode=$(cat <<EOF
# Returns EDB-IDs for unverified exploits
import json
import sys

# Extract and load the RESULTS_EXPLOIT node of the searchsploit JSON output
results_exploit = json.load(sys.stdin)['RESULTS_EXPLOIT']

# Filter it for entries that have Verified set to zero. Return their EDB-IDS
unverified_exploits = [x['EDB-ID'] for x in results_exploit if x['Verified'] == '0']
print(unverified_exploits)
EOF
)

# Only apply the postprocessing when the flags used are search term related or none are used
if [ $1 = "-m" ] || [ $1 = "--mirror" ] || [ $1 = "-x" ] || [ $1 = "--examine" ] || [ $1 = "-h" ] || [ $1 = "--help" ] || [ $1 = "-u" ] || [ $1 = "--update" ]
then
	searchsploit '--exclude=/dos/' "$@"
else
	# Sends json to above python code. Removes python array structure from output and concats the EDB-IDs with "/|", so that grep can understand it
	pattern=$(searchsploit -j "$@" | python3 -c "$pycode" | tr -d '['-']' | sed "s/'//g" | sed 's/, /\\\|/g')
	
	# Runs searchsploit and hightlights EDB-IDs in the output that match the EDB-IDs in $pattern
	searchsploit '--exclude=/dos/' "$@" | grep --color -e "$pattern" -e '^'
fi



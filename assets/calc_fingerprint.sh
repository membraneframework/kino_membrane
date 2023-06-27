#!/usr/bin/env bash
# this prints arguments to stdout, finds all files in directories
# passed as arguments and calculates sha of each of them
# finally, the entire output is written to a .fingerprint file
(echo $@ && find $@ -type f -print0 | xargs -0 sha256sum) > $1.fingerprint

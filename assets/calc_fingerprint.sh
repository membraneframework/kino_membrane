#!/usr/bin/env bash
(echo $@ && find $@ -type f -print0 | xargs -0 sha256sum) > $1.fingerprint

#!/bin/bash

OUTDIR="/var/log/varnish-vcl"
OUTFILE="$OUTDIR/vcl-$(date +%Y-%m-%d_%H%M).log"

mkdir -p "$OUTDIR"

timeout 10 varnishlog -n varnishd -g raw -i VCL_call,VCL_return,CLI \
  > "$OUTFILE"

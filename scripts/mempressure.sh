#!/bin/bash

if [[ "$OSTYPE" == "linux"* ]]; then
    OUT=$(free | grep Mem | awk '{printf "%.0f", (1 - $7/$2) * 100.0}');
    echo "$OUT%";
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OUT=$(memory_pressure -Q | tail -n 1 | python -c 'import sys; print("{}%".format(100 - int(sys.stdin.read().split()[-1].strip("%"))))');
    echo $OUT;
fi


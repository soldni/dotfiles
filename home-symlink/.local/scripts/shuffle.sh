#!/bin/bash
case "$#" in
    0) echo "Usage: $0 files....." ; exit 1;;
esac

ORDER="./.rand.$$"
trap "rm -f $ORDER;exit" 1 2
count=$(grep -c '^' "$1")

let odcount=$(($count * 4))
paste -d" " <(od -A n -N $odcount -t u4 /dev/urandom | grep -o '[0-9]*') <(seq -w $count) |\
    sort -k1n | cut -d " " -f2 > $ORDER

#if your system has the "shuf" command you can replace the above 3 lines with a simple
#seq -w $count | shuf > $ORDER

for file in "$@"
do
    paste -d' ' $ORDER $file | sort -k1n | cut -d' ' -f2-  > "$file.shuffled"
done

echo "the order is in the file $ORDER"  # remove this line
#rm -f $ORDER                           # and uncomment this
                                        # if dont need preserve the order


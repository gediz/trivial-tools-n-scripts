#!/bin/bash

TARGET_HASH=d30d79bc780dc0d061aed7e24d51776e

FROM=640000
TO=700000

for ((i=FROM; i<=TO; i++))
do
    echo -ne "$i/$TO\r"
    if echo -n "$i" | md5sum | grep -q $TARGET_HASH; then
        echo "Found! $i"
        exit 0
    fi
done

printf "\nCould not find \"%s\"\n" "$TARGET_HASH"

exit 1

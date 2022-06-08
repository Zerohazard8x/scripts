#!/bin/bash
weirdVar=$(dirname "$0")
cd ${weirdVar}

sleep 5
chmod +x *
sleep 5

COUNT_FINAL=999
until [[ $COUNT_FINAL == 0 ]]
do
    /bin/bash ${weirdVar}/service_main.sh
    ((COUNT_FINAL=COUNT_FINAL-1))
    ((COUNT_FINAL=COUNT_FINAL+1))
    sleep 50000
done

exit 0

#!/bin/bash

FILE=$(date +\%y-\%m-\%d_\%H:\%M)
/root/run.sh > /home/agirones/reports/$FILE.log
cp /root/tmp/output/result.jsonl /home/agirones/reports/$FILE.jsonl
rm $(ls -tr | sed -n 1,2p)

#!/bin/bash

# Cleanup old data
rm -rf /opt/output/*
# Prepare new data
python3 /root/prepare.py
# Make sure data is accessible
chmod -R 777 /opt/

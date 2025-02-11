#!/bin/bash

read password
#./configureswitch.sh konexioais $password sw-test-prod00 ttyACM0

./configureswitch.sh konexioais $password sw-admin00 172.16.0.254 ttyACM0
./configureswitch.sh konexioais $password sw-front00 172.16.5.254 ttyACM0

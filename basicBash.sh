#! /bin/bash

# I want to run a script to change the mac address and then clear the history in bash and memory

# These are basic commands that will change the mac

ifconfig wlan0 down
macchanger -r wlan0
ifconfig wlan0 up

# These are to clear the history 

# history -c
# history -w




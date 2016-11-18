#! /usr/bin/expect -f
 
# This will call to the Pi and estabish the full connection

spawn ssh pi@localhost -p 56225
sleep 3
expect "password:"
sleep3
send "raspberry"
interact

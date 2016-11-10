#! /usr/bin/expect -f

# This will shut down the wifi that is standard on the Pi3
# sudo ifconfig wla0 down

# This will the GSM module an interface for internet connection
# sudo pon fona

# This will open designated port and normal ssh login
# spawn ssh -R 62225:localhost:22 root@159.203.254.183 
# sleep 3

# This will call back to the source system and log in with your password 
expect "password:"
sleep 3
send "testServ%80%\r"
interact

### This will call back to the Pi and estabish the full connection

# sleep 3
# spawn ssh pi@localhost -p 62225 
# sleep 3
# expect "password:"
# sleep3
# send "raspberry"
#interact

###



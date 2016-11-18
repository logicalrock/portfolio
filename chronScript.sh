#! /usr/bin/expect -f

# This is the if statement that the chron job should itterate through and checking the number of instances of SSH running

if (( $(netstat -anp | grep -c ssh | grep -c ESTABLISHED) < 1 )); then
        print "Starting New SSH Tunnel Connection"
# This will shut down the wifi that is standard on the Pi3
        sudo ifconfig wla0 down
# This will the GSM module an interface for internet connection
		sudo pon fona
		sleep 3
# This will open designated port and normal ssh login
        spawn ssh -R 56225:localhost:22 root@159.203.254.183
		sleep 3
# This will wait for the password prompt and tell the script it is ready
		expect "password:"
		sleep 3
# This will enter the known password to establisht the reverse tunnel
		send "testServ%80%\r"
		interact
fi


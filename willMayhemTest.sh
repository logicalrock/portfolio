#! /bin/bash

sshpass -ptestServ%80% ssh -R 56225:localhost:22 root@159.203.254.183 ls -l /tmp

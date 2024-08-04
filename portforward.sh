#!/bin/bash
# Builds a ssh tunnel from the client host to the inspector server (using redc01as intermediate hosts)
# which forwards the first argument port on the client host to the second argument port on the inspector server.
# Example: 
# portforward.sh 1234 22 
# On the client issuing the command you can now use 
# scp -P1234 somefile.txt inspectr@localhost:
# to copy files to/from inspector server
#
# Andreas Grieger, 25/01/2002
# Andreas Grieger, 02/05/2002, changed to use redc01

#ssh -g -t -L $1:localhost:$1 infonie@195.232.84.190 ssh -t -L $1:localhost:$1 infonie@193.189.233.18 ssh -t -L $1:localhost:$2 inspectr@192.168.101.144
ssh -g -t -L $1:localhost:$1 infonie@redc01.preview.aol.de ssh -t -L $1:localhost:$2 services@10.146.46.36

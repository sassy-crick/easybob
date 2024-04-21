#!/bin/bash
# post-installation script to make sure the created files are actually ending up
# in the software directory.
# We first remove all the .wq files and then just rsync the files over. 
# We need to find a better way of doing that as we also need to change the permissions!
# This was only needed when we wrongly used fusermout-fs for the EasyBuild. We actually don't need 
# that. That said, it might be good to keep that for documentation purposes

# Remove all the .wq files and the .locks directory:
find /dev/shm/jsassman/upper/ -name ".wh..wh..opq"  -exec rm {} \;
find /dev/shm/jsassman/upper/ -name ".wh..opq"  -exec rm {} \;
rmdir /dev/shm/jsassman/upper/software/.locks

# Make sure all the permissions are set correctly:
chmod -R  g=rX,o=rX /dev/shm/jsassman/upper/

# Copy all the files to the correct working directory. We need to check the permissions!
# rsync -rlpgtDv --numeric-ids --chown=:sw--admin /dev/shm/jsassman/upper/ /apps/eb-softwarestack/generic/apps 
rsync  -rlpgtDv --numeric-ids --chown=:sw--admin /dev/shm/jsassman/upper/ /rds/general/user/jsassman/home/testing/buildstuff/generic/apps/

if [ $? -eq 0 ]; then rm -rf /dev/shm/jsassman/upper/* ; fi

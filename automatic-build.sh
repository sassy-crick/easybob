#!/usr/bin/env bash
# Submission script which will start the automatic build process.
# We are basically sourcing the site-conf file to get all the variables
# for SLURM we need. As right now we are only having one architecture, we 
# are not using a loop for all architectures. 
# The script expects the path to be the first argument. 
# 15.12.2021: Initial, primitive script
# Updated for HX1, making it a bit more flexible so different site-config
# files can be used, depending on the cluster

# Where is the script located?
#BASEDIR=$(dirname "$0")
BASEDIR=$PWD

# Some defaults which we get from the site-config environment file
# We first check which cluster we are on and if none is set, we fall back
# to the site-config file.
# This is only a stepping stone until we got all of the hardware on CX3 in
# the new OS!

cluster=$(hostname  | cut -d "-" -f 1)

if [ ${cluster} != "hx1" ]; then
        clustercx=$(hostname -f | cut -d "." -f 1)
        case ${clustercx} in
                login-a|login-b|login-c|login-dev)
                source ${BASEDIR}/site-config
                SITECONFIG=site-config
                cluster=CX3-old
                ;;
                login-ai|login-bi)
                source ${BASEDIR}/cx3-intel-config
                SITECONFIG=cx3-intel-config
                cluster=CX3-new
        esac
fi

# This is how it eventually should look like:

#cluster=$(hostname  | cut -d "." -f 2)
#case ${cluster} in
#        hx1)
#        source ${BASEDIR}/hx1-config
#        SITECONFIG=hx1-config
#        ;;
#        cx3)
#        source ${BASEDIR}/cx3-config
#        SITECONFIG=cx3-config
#        ;;
#        *)
#        source ${BASEDIR}/site-config
#        SITECONFIG=site-config
#esac

echo 'Installing software on Cluster' ${cluster}

# We need to know the path where to find the EasyStack file for example.
if [ -s "$1" -a -d "$1" ]; then
        WORKINGDIR="$1"
else
        echo "The ${WORKINGDIR} does not appear to be a directory!"
        echo "Bombing out!"
        exit 2
fi

# We need to check if in the workingdir the softwarelist.txt or
# softwarelist.yaml file exist
if [  -e ${WORKINGDIR}/softwarelist.txt ]; then
		echo "The file softwarelist.txt was found and contains:"
		cat ${WORKINGDIR}/softwarelist.txt
		# Nice to have the name of the software to be installed instead of just
		# ARCH-build
		SW_NAME=$(awk -F " " '{print $NF}' ${WORKINGDIR}/softwarelist.txt | cut -d "-" -f 1)
	elif [  -e ${WORKINGDIR}/softwarelist.yaml ]; then 
		echo "The file softwarelist.yaml was found and contains:"
		cat ${WORKINGDIR}/softwarelist.yaml
else
	echo "Neither softwarelist.txt nor softwarelist.yaml were found!"
	echo "Bombing out!"
	exit 2 
fi

# We are installing binary files in the noarch folder as they are install
# only, no building. This way, we are avoiding having the same files around
# for a number of times. 
# We simply test if the site-configuration file, sources above, contains a 
# NOARC variable. If so, we are using it. 
if [ -n $NOARCH ]; then
        noarchtest=$(echo $NOARCH | grep $SW_NAME &> /dev/null; echo $?)
        if [ $noarchtest -eq 0 ]; then
                echo "noarch is set so we install in the noarch folder only"
                export ARCH=noarch
		export PLATFORMS=noarch
        fi

fi

####
# Some software is proprietary, so we need to put that in a special group
# Unfortunately, within a container the chown command is defaulting to 'nobody'
# which is not what we want to have. Thus, we checking if the softwarelist.txt file
# contains a name which is in a list, defined in the site-configuration file. 
# If it is in that list, we are using the 'newgrp' command to run the container as that 
# group, rather then the default one. 

####

# Make sure the directories are in place
mkdir -p ${WORKINGDIR}/{logs,scripts}

# We check if a cuda enables software was submitted. 
cudatest=$(grep -i 'cuda' ${WORKINGDIR}/softwarelist* &> /dev/null; echo $?)
if [ $cudatest -eq 0 ]; then
	echo "This software installation is running only on the GPU node"
	PLATFORMS=${GPUPLATFORMS}
fi

for i in $PLATFORMS ; do
$i
echo $i 
# echo arch is $ARCH
# This is for EasyBuild installations (or both)
if [[ ${INSTALLING} == "EB" || ${INSTALLING} == "BOTH" ]] ; then

cat <<EOF> ${WORKINGDIR}/scripts/${ARCH}-submission.sh
#!/usr/bin/env bash 
# This is for PBSpro. We might need to add to this!
#PBS -lselect=1:ncpus=${CORES}:mem=100gb${PARTITION}
#PBS -lwalltime=${WALLTIME} 
#PBS -q ${QUEUE}
#PBS -e ${WORKINGDIR}/logs/
#PBS -o ${WORKINGDIR}/logs/
#PBS -N ${SW_NAME}-${ARCH}-build

export BASEDIR=${BASEDIR}
export SITECONFIG=${SITECONFIG}
export CORES=${CORES}
export CUDA_COMPUTE_CAPABILITIES=${CUDA_COMPUTE_CAPABILITIES} 
if [ -n "${EASYBUILD_OPTARCH}" ]; then
        export OPTARCH="${EASYBUILD_OPTARCH}"
fi

# Now we run the job:
${BASEDIR}/easybuild/install.sh ${WORKINGDIR} ${ARCH}; echo \$? 
if [ \$? -eq 0 ]; then
	echo "We are testing the installed software on a different container"
	${BASEDIR}/easybuild/testing.sh ${WORKINGDIR} ${ARCH} 
else
	echo "There was a problem with the installation!"
fi

EOF
qsub ${WORKINGDIR}/scripts/${ARCH}-submission.sh

fi

# THIS IS NOT TESTED YET!!!
# This is for EESSI installations (or both)
if [[ ${INSTALLING} == "EESSI" || ${INSTALLING} == "BOTH" ]] ; then

cat <<EOF> ${WORKINGDIR}/scripts/${ARCH}-eessi-submission.sh
#!/usr/bin/env bash
# This is for PBSpro. We might need to add to this!
#PBS -lselect=1:ncpus=${CORES}:mem=50gb:cpu_type=${PARTITION}
#PBS -lwalltime=24:00:0
#PBS -e ${WORKINGDIR}/logs/${ARCH}.err
#PBS -o ${WORKINGDIR}/logs/${ARCH}.out
#PBS -N ${ARCH}-build

export EESSI_PILOT_VERSION=2021.12
EESSI_TMPDIR=/tmp/eessi

mkdir -p \${EESSI_TMPDIR}/software
cp -R ${BASEDIR}/eessi/software-layer \${EESSI_TMPDIR}
cp ${BASEDIR}/eessi/software-layer/EESSI-pilot-install-software-easystack.sh \${EESSI_TMPDIR}/software-layer
cp ${WORKINGDIR}/softwarelist.yaml \${EESSI_TMPDIR}/software/easystack.yml
cd \${EESSI_TMPDIR}/software-layer

echo \$PWD

./build_container.sh run \${EESSI_TMPDIR} ./run_in_compat_layer_env.sh ./EESSI-pilot-install-software-easystack.sh
if [ \$? -eq 0 ]; then
    # right now the ARCH seems to be set to Haswell, which is wrong as we are on Zen2
    # So we simply set that here to zen2
    # This should be automatically determined but somehow that does not work for the tarball it seems. 
    EESSI_SOFTWARE_SUBDIR=\$(cat /dev/shm/EESSI_SOFTWARE_SUBDIR)
    echo "Architecture is \$EESSI_SOFTWARE_SUBDIR"
    TARBALL=\${EESSI_TMPDIR}/eessi-\${EESSI_PILOT_VERSION}-software-linux-${ARCH////-}-$(date +'%s').tar.gz
    ./build_container.sh run \${EESSI_TMPDIR} ./create_tarball.sh \${EESSI_TMPDIR} \${EESSI_PILOT_VERSION} \${EESSI_SOFTWARE_SUBDIR} \${TARBALL}
    cp \${TARBALL} ${WORKINGDIR}
fi
EOF

# qsub ${WORKINGDIR}/scripts/${ARCH}-eessi-submission.sh
fi

done


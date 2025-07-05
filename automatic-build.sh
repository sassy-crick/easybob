#!/usr/bin/env bash
# Submission script which will start the automatic build process.
# We are basically sourcing the site-conf file to get all the variables
# for SLURM we need. As right now we are only having one architecture, we 
# are not using a loop for all architectures. 
# The script expects the path to be the first argument. 
# 15.12.2021: Initial, primitive script
# Updated for HX1, making it a bit more flexible so different site-config
# files can be used, depending on the cluster
# 6.5.2025: updated to EasyBuild-5, also some more tidy up

# Where is the script located?
BASEDIR=$(dirname "$0")

# Some defaults which we get from the site-config environment file
# We first check which cluster we are on. HX1 and CX3 have different names, 
# so we simply check if we are not on HX1 and thus on the CX3 clusters.

cluster=$(hostname  | cut -d "-" -f 1)

if [ ${cluster} != "hx1" ]; then
        clustercx=$(hostname -f | cut -d "." -f 1)
        case ${clustercx} in
                login-a|login-c)
                cluster=CX3-old
                ;;
                login-ai|login-bi|login-b|login-dev)
                cluster=CX3-Phase2
        esac
fi

# Now we know which cluster we are on, so we are sourcing the relevant file. 
# This way, it is hopefully a bit easier to read then a convoluted script. 
case ${cluster} in
        hx1)
        source ${BASEDIR}/hx1-config
        SITECONFIG=hx1-config
        ;;
        CX3-old)
        source ${BASEDIR}/cx3-config
        SITECONFIG=cx3-config
        ;;
        CX3-Phase2)
        SITECONFIG=cx3-phase2-config
        source ${BASEDIR}/${SITECONFIG}
        ;;
        *)
        echo -e "\e[1;31mNo site-config file was found. Stopping here\e[0m"
        exit 2
esac

# We want to be cutting edge with the software installation, so every time we run the script
# we simply do a git-pull on the EasyConfig Github folder.
# We do that first so we then can do the copy&paste for the job-submission if we want to save that
# somewhere.

if [ -d ${GITHUBEC} ]; then
        echo -e "\e[1;36mUpdating GitHuB EasyConfig folder\e[0m"
        cd ${GITHUBEC}
	pwd
        git pull origin develop
        cd -
fi

echo -e 'Installing software on Cluster' "\e[1;36m${cluster}\e[0m"
echo 'Using the site-configuration file' ${SITECONFIG}

# We need to know the path where to find the relevant informations.
if [ -s "$1" -a -d "$1" ]; then
        WORKINGDIR="$1"
else
	WORKINGDIR=$PWD
	echo "The current directory is ${WORKINGDIR}" 
fi

# We need to check if in the workingdir the softwarelist.txt or
# softwarelist.yaml file exist
if [  -e ${WORKINGDIR}/softwarelist.txt ]; then
		echo "The file softwarelist.txt was found and contains:"
		cat ${WORKINGDIR}/softwarelist.txt
		# Nice to have the name of the software to be installed instead of just
		# ARCH-build
		# This will not work if we are using --from-pr as the name is not there. 
		# So we check for that first:
		if [ $(grep from-pr ${WORKINGDIR}/softwarelist.txt &>/dev/null ; echo $?) == 1 ]; then
			SW_NAME=$(awk -F " " '{print $NF}' ${WORKINGDIR}/softwarelist.txt | cut -d "-" -f 1)
		else
			SW_NAME="PR-build"
		fi
	elif [  -e ${WORKINGDIR}/softwarelist.yaml ]; then 
		echo "The file softwarelist.yaml was found and contains:"
		cat ${WORKINGDIR}/softwarelist.yaml
else
	echo -e "\e[1;31mNeither softwarelist.txt nor softwarelist.yaml were found!\e[0m"
	echo -e "\e[1;31mStopping here!\e[0m"
	exit 2 
fi

# We are installing binary files in the noarch folder as they are install
# only, no building. This way, we are avoiding having the same files around
# for a number of times. 
# We simply test if the site-configuration file, sources above, contains a 
# NOARC variable. If so, we are using it. 
if [[ -n "${NOARCH}" ]]; then
	# Looping over all possible settings
	for i in $NOARCH ; do if [ $i == $SW_NAME ]; then NOARCHTEST=1; fi; done

        if [[ ${NOARCHTEST} -eq 1 ]]; then
                echo "noarch is set so we install in the noarch folder only"
                export ARCH=noarch
		export PLATFORMS=noarch
        fi
fi


# Some software does not like long log-path. So here we check for them and put
# the log files into /dev/shm/$USER
# We simply test if the site-configuration file, sources above, contains a 
# SHORTLOG variable. If so, we are using it. 
if [[ -n "${SHORTLOG}" ]]; then
	# Looping over all possible settings
	for i in $SHORTLOG ; do if [ $i == $SW_NAME ]; then SHORTLOG=1; fi; done

        if [[ ${SHORTLOG} -eq 1 ]]; then
                echo "SHORTLOGDIR is set so we are using /dev/shm/$USER for the log-files"
                export EASYBUILD_TMPDIR="/dev/shm/$USER"
		export SHORTLOGDIR="ON"
	else
		export SHORTLOGDIR="OFF"
        fi
fi

# Some software has problems to run the test-jobs inside a container. IF that is a binary
# then we simply ignore the test-jobs at all. After all, we cannot rebuild a binary
# distributed software
if [[ -n "${NOTESTS}" ]]; then
	# Looping over all possible settings
	for i in $NOTESTS ; do if [ $i == $SW_NAME ]; then NOTESTS=1; fi; done

        if [[ ${NOTESTS} -eq 1 ]]; then
                echo "NOTESTS is set so we are not running any test jobs"
                export EASYBUILD_SKIP_TEST_STEP="True"
		NOTESTS="ON"
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
#PBS -lselect=1:ncpus=${CORES}:mpiprocs=${CORES}:mem=100gb${PARTITION}
#PBS -lwalltime=${WALLTIME} 
#PBS -q ${QUEUE}
#PBS -e ${WORKINGDIR}/logs/
#PBS -o ${WORKINGDIR}/logs/
#PBS -N ${SW_NAME}-${ARCH}-build

export BASEDIR=${BASEDIR}
export SITECONFIG=${SITECONFIG}
export CORES=${CORES}
EOF
if [ -n "${CUDA_COMPUTE_CAPABILITIES}" ]; then
	echo "We are using the following CUDA-compute-capabilities settings:" ${CUDA_COMPUTE_CAPABILITIES}
	echo 'export CUDA_COMPUTE_CAPABILITIES='\"${CUDA_COMPUTE_CAPABILITIES}\" >>  ${WORKINGDIR}/scripts/${ARCH}-submission.sh
fi

if [ -n "${EASYBUILD_OPTARCH}" ]; then
	echo "We are using the following Optarch settings:" ${EASYBUILD_OPTARCH}
        echo 'export EASYBUILD_OPTARCH='\""${EASYBUILD_OPTARCH}"\" >>  ${WORKINGDIR}/scripts/${ARCH}-submission.sh
fi

# Currently not working as I would like to have it
#if [ "${SHORTLOGDIR}" == "ON" ]; then 
#        echo 'export EASYBUILD_TMPDIR="/dev/shm/$USER"' >>  ${WORKINGDIR}/scripts/${ARCH}-submission.sh
#        echo "The temp dir is set to" $EASYBUILD_TMPDIR
#fi

if [ "$NOTESTS" == "ON" ]; then
	echo 'export EASYBUILD_SKIP_TEST_STEP="True"' >>  ${WORKINGDIR}/scripts/${ARCH}-submission.sh
        echo 'export NOTESTS="ON"' >>  ${WORKINGDIR}/scripts/${ARCH}-submission.sh
	echo 'No Test jobs are being run!'
fi

cat <<EOF>> ${WORKINGDIR}/scripts/${ARCH}-submission.sh

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


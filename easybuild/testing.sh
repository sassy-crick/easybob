#!/usr/bin/env bash
# Script for the automatic testing of installed software
# We are using different singularity container than the one for the installation
# so we are testing on a different OS
# 16/12/2021: Singularity container to EB 4.5.0 upgraded
#             Initial tests. This script is based on the install.sh script
# 22/01/2022: Added ARCH which will be handed over from the automatic-build.sh 
#             script
# 11/08/2022: Removed all the overlay stuff as that is not really needed. 
#             Also done some further clean up.
# 23/06/2023: Script adapted to HX1, which also means some modularity has been added
#             to run on different clusters

# Where is the script located?
# BASEDIR=$PWD/easybuild

# We need to know the path where to find the EasyStack file for example. 
if [ -s "$1" -a -d "$1" ]; then
	WORKINGDIR="$1"
else
	echo "The ${WORKINGDIR} does not appear to be a directory!"
	echo "Bombing out!"
	exit 2
fi

# We need to know which architecture we are running on.
# Right now, that happens at submission time

if [ -n "$2" ]; then 
        ARCH="$2"
else
        echo "No architecture was defined, so we are stopping here!"
        exit 2
fi

if [[ -d "${BASEDIR}" ]] && [[ -n "${SITECONFIG}" ]]; then
        basedir="${BASEDIR}"/easybuild
        siteconfig="${BASEDIR}"/"${SITECONFIG}"
        # Some defaults which we get from the site-config environment file
        source ${siteconfig}
        echo "The site configuration file" ${siteconfig} "is being used"
        echo $CORES "Cores are being used"
	echo "The specific settings for ${ARCH} are being used"
        ${ARCH}
else
        echo "The ${BASEDIR} does not appear to be a directory!"
        echo "Bombing out!"
        exit 2
fi

# We need to set the right paths first.
# We do that via variables up here:
# These are the only bits which need to be modified:
# The first one is for a list of EasyConfig files
SW_NAME="${WORKINGDIR}/softwarelist.txt"
# This one is for an EasyStack file in yaml format:
SW_YAML="${WORKINGDIR}/softwarelist.yaml"
# Right now we don't have access to /tmp, so we are using our ephemeral instead
EB_TMPDIR="${EPHEMERAL}"

# For the Intel compilers, IMPI is expecting a hostfile in  /var/spool/pbs/aux
# So we need to bind-mount that. 
PBSHOSTFILE="/var/spool/pbs/aux"

#########################################################################################
# These should not need to be touched
# Future development for EESSI
OVERLAY_BASEDIR="${SOFTWARE_HOME}"
OVERLAY_LOWERDIR="${OVERLAY_BASEDIR}/apps"
OVERLAY_UPPERDIR="/dev/shm/${USER}/upper"
OVERLAY_WORKDIR="/dev/shm/${USER}/work"
if [ ${ARCH} == "develop" ]; then
        OVERLAY_MOUNTPOINT="/apps/sw-eb"
else
        OVERLAY_MOUNTPOINT="/sw-eb"
fi
CONTAINER="${CONTAINER_DIR}/${CONTAINER_TESTING_VERSION}"
SCRIPTS_DIR="${WORKINGDIR}/${ARCH}/${PBS_JOBID}/scripts"
SOFTWARE="${SCRIPTS_DIR}/software.sh"
LOG_DIR="${WORKINGDIR}/${ARCH}/${PBS_JOBID}/logs"
#########################################################################################

echo "Testing started at started at $(date)"
# set +ve
# We check if the folders exist 
if [ ! -d ${SOFTWARE_INSTDIR} ]; then
	echo "It appears that ${SOFTWARE_HOME} does not exist"
	echo "Please make sure the provided path is correct and make the required directory"
	echo "Bombing out here."
	exit 2
fi

# We check if the singularity container exists
if [ ! -f ${CONTAINER} ]; then
	echo "The Singularity Container ${CONTAINER} does not exist!"
	echo "Please install the container before you can continue."
	echo "Bombing out here."
	exit 2
fi

# We need to export these variables so we can modify the template for the software to be installed
export EASYBUILD_ACCEPT_EULA_FOR
export EASYBUILD_SOURCEPATH
export EASYBUILD_INSTALLPATH
export EASYBUILD_BUILDPATH
export MODULEPATH
export EB_VERSION
export EB
# export SW_LIST # we do this further down!
export SW_YAML
export WORKINGDIR
export ARCH
export EASYBUILD_TMPDIR=${LOG_DIR}

# We make a scripts and log directory in the working-directory, as that one is unique to all builds.
mkdir -p ${SCRIPTS_DIR} ${LOG_DIR}

# We create the software.sh file on the fly in the right place. Any previous version will be removed.
envsubst '${EASYBUILD_ACCEPT_EULA_FOR},${EASYBUILD_SOURCEPATH},${EASYBUILD_INSTALLPATH},${CORES},${EASYBUILD_BUILDPATH},${MODULEPATH},${EB_VERSION},${EASYBUILD_TMPDIR}' < ${BASEDIR}/easybuild/software-head.tmpl > ${SOFTWARE}

# echo some environment variables, so set
if [ "${EASYBUILD_SKIP_TEST_STEP}" == "True" ]; then
        echo "####################################################################'"
        echo "WARNING! NO TESTS WILL BE PERFORMED! MAKE SURE YOU KNOW WHAT YOU DO!!"
        echo "####################################################################'"
        echo 'export EASYBUILD_SKIP_TEST_STEP == "True"' >> ${SOFTWARE}
fi

if [ -s ${SW_NAME} ]; then
        SW_LIST=$(cat ${SW_NAME})
        export SW_LIST
        envsubst '${EB},${SW_LIST},${WORKINGDIR}' < ${BASEDIR}/easybuild/software-list-test.tmpl >> ${SOFTWARE} 
fi
if [ -s ${SW_YAML} ]; then
        envsubst '${EB},${SW_YAML},${WORKINGDIR}' < ${BASEDIR}/easybuild/software-yaml-test.tmpl >> ${SOFTWARE} 
        cp -f ${SW_YAML} ${SCRIPTS_DIR}
fi

chmod a+x ${SOFTWARE}

# For the GPU nodes, we need to export the CUDA_VISIBLE_DEVICES else that will not work. We are only
# doing that on the GPU nodes and are only exporting one GPU, hence the 0

if [[ ${ARCH} == "skylake" ]] || [[ ${ARCH} == "zen2" ]] || [[ ${ARCH} == "gpu" ]] ; then
        export CUDA_VISIBLE_DEVICES=0
        NV_FLAG="--nv"
else
        NV_FLAG=""
fi

# We check if we already have an EasyBuild module file.
# If there is none, we stop here as something went wrong. 
# If the directory exist and the requested EasyBuild version is there, we simply test the
# software stack which we provide. 
if [ -e ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}.lua ]; then
	echo "We are testing the software as defined in ${SOFTWARE} "
	echo "in container version ${CONTAINER_TESTING_VERSION}"
        cat "${SOFTWARE}"
	# We can execute the container and tell it what to do:
 	singularity exec ${NV_FLAG} --bind ${BINDDIR} --bind ${OPTDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
	--bind ${PBSHOSTFILE}:${PBSHOSTFILE} ${CONTAINER} ${SOFTWARE}
else
	echo "It appears that there is no module file for ${EB_VERSION}.lua, so we stop here!"
	exit 3
fi

echo "Testing finished at $(date)"


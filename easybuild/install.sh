#!/usr/bin/env bash
# Script for the automatic installation of software
# We are using a singularity container for the installation
# so we are isolated from the OS
# This script does the actual installation.
# The software stack, so to speak will be in the 
# software.sh script. That will be replaced with a yml file
# later for production. 
# 28/10/2021: initial testing
# 09/11/2021: some tidy up
# 18/11/2021: Singularity container to EB 4.4.2 upgraded
# 23/11/2021: Installation path changed to /apps/easybuild
# 15/12/2021: Including a site specific site-config enfironment file which
#             contains all the configurable variables, so we got one place
#             to rule them all.
#             We also hand over the full path where to find the EasyStack file 
#             for example. This is also where any output files will go to. 
#             The WORKINGDIR comes from the GitHub app and will change for each 
#             run
# 22/01/2022: Added ARCH which will be handed over from the automatic-build.sh 
#             script
# 22/04/2022: Removed all the overlay stuff as that is not really needed. 
#             Also done some further clean up.
# 23/06/2023: Script adapted to HX1, which also means some modularity has been added
#             to run on different clusters

# Where is the script located?
# BASEDIR=$(dirname "$0")
# BASEDIR=$PWD/easybuild

# The umask on the nodes is set to 0077 which is causing problems for the software
# installation, so we need to change that:
umask 0022

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
	export ARCH=${ARCH}
else
	echo "No architecture was defined, so we are stopping here!"
	exit 2
fi

echo "Installation started at $(date)"

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
	echo "The basedirectory ${BASEDIR} does not appear to be a directory or siteconfiguration file ${SITECONFIG} could not be found!"
	echo "Bombing out!"
	exit 2
fi

# We need to set the right paths first.
# We do that via variables up here:
# These are the only bits which need to be modified:
# Where to install the software:
# SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}" # this comes from the site-config file
# The first one is for a list of EasyConfig files
SW_NAME="${WORKINGDIR}/softwarelist.txt"
# This one is for an EasyStack file in yaml format:
SW_YAML="${WORKINGDIR}/softwarelist.yaml"
# Right now we don't have access to /tmp, so we are using our ephemeral instead
EB_TMPDIR="${EPHEMERAL}"
# We might need to change that. Right now we are having the generic develop build as
# defined in the site-config file, and the architecture specific builds here.
# At the next maintanence window, we might want to sort that out better!
# This has been sorted now, so here we do the production build
#if [ ${ARCH} != "develop" ]; then
#	SOFTWARE_INSTDIR="/rds/easybuild"
#	MODULEPATH="/sw-eb/modules/all"
#	EASYBUILD_INSTALLPATH="/sw-eb"
#	SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}" # this is for the development software stack
#fi

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
# Used for EasyBuild
SOFTWARE_HOME="${SOFTWARE_INSTDIR}/${ARCH}/apps"
CONTAINER="${CONTAINER_DIR}/${CONTAINER_VERSION}"
SCRIPTS_DIR="${WORKINGDIR}/${ARCH}/${PBS_JOBID}/scripts"
SOFTWARE="${SCRIPTS_DIR}/software.sh"
LOG_DIR="${WORKINGDIR}/${ARCH}/${PBS_JOBID}/logs"
#########################################################################################


# We check if the folders are here, if not we install them
if [ -d ${SOFTWARE_INSTDIR} ]; then
	echo "Making sure all directories exist in ${SOFTWARE_INSTDIR}/${ARCH} "
	mkdir -p ${SOFTWARE_HOME}
	mkdir -p ${SOFTWARE_INSTDIR}/sources
	mkdir -p ${SCRIPTS_DIR}
else
	echo "It appears that ${SOFTWARE_INSTDIR} does not exist"
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

# This is for CUDA, if we are using it:
export CUDA_COMPUTE_CAPABILITIES

# This is to dynamically set where EasyBuild is writing out the various temporary files. The setting is 
# done in the site-configuration file. 

if [ ${EASYBUILD_TMPDIR} == "logdir" ]; then
	export EASYBUILD_TMPDIR="${LOG_DIR}"
else
	export EASYBUILD_TMPDIR="/dev/shm/$USER"
fi

# We make a scripts and log directory in the working-directory, as that one is unique to all builds.
mkdir -p ${SCRIPTS_DIR} ${LOG_DIR}

# We create the software.sh file on the fly in the right place. Any previous version will be removed.
envsubst '${EASYBUILD_ACCEPT_EULA_FOR},${EASYBUILD_SOURCEPATH},${EASYBUILD_INSTALLPATH},${CORES},${EASYBUILD_BUILDPATH},${EASYBUILD_TMPDIR},${MODULEPATH},${EB_VERSION}}' < ${BASEDIR}/easybuild/software-head.tmpl > ${SOFTWARE} 
if [ -n "${OPTARCH}" ]; then
	echo "# We are setting OPTARCH here" >> ${SOFTWARE}
	echo "export EASYBUILD_OPTARCH='${OPTARCH}'" >> ${SOFTWARE}
fi
if [ -s ${SW_NAME} ]; then
        SW_LIST=$(cat ${SW_NAME})
        export SW_LIST
        envsubst '${EB},${SW_LIST},${CUDA_COMPUTE_CAPABILITIES}' < ${BASEDIR}/easybuild/software-list.tmpl >> ${SOFTWARE} 
fi
if [ -s ${SW_YAML} ]; then
        envsubst '${EB},${SW_YAML},${CUDA_COMPUTE_CAPABILITIES}' < ${BASEDIR}/easybuild/software-yaml.tmpl >> ${SOFTWARE} 
        cp -f ${SW_YAML} ${SCRIPTS_DIR}
fi
cat ${BASEDIR}/easybuild/software-bottom.tmpl >> ${SOFTWARE}
chmod a+x ${SOFTWARE}

# For the GPU nodes, we need make sure the container is using the allocated GPUs. 
# The allocation is done via the PBSPro but we need to set the '--nv' flag
# We are using the CUDA_COMPUTE_CAPABILITIES to check if it is a GPU install or not. 

if [ -n "${CUDA_COMPUTE_CAPABILITIES}" ]; then
        NV_FLAG="--nv"
        ovl=/dev/shm/overlay_$$
        mkdir -p ${ovl}
	opencl="/etc/OpenCL"
else
        NV_FLAG=""
fi

# We check if we got the fuse-overly installed and if not, install it
# Right now, we don't need that any more but we leave it for reference purposes
# if [ ! -f ${OVERLAY_BASEDIR}/fuse-overlayfs ]; then
#	 curl -o ${OVERLAY_BASEDIR}/fuse-overlayfs -L https://github.com/containers/fuse-overlayfs/releases/download/v1.8.2/fuse-overlayfs-x86_64 
#	 chmod a+x ${OVERLAY_BASEDIR}/fuse-overlayfs  
# fi

# We check if we already have an EasyBuild module file.
# If there is none, we assume it is a fresh installation and so we need
# to upgrade EasyBuild to the latest version first before we can continue
if [ ! -d ${SOFTWARE_HOME}/modules/all/EasyBuild ]; then
		singularity exec --bind ${BINDDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
		${CONTAINER} ${EB} --prefix=${SOFTWARE_HOME} --installpath=${EASYBUILD_INSTALLPATH} --install-latest-eb-release
	elif [ ! -e ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}* ]; then
	       	echo "We are upgrading EasyBuild to the latest version."
		# We can execute the container and tell it what to do:
		singularity exec --bind ${BINDDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
		${CONTAINER} ${EB} --prefix=${SOFTWARE_HOME} --installpath=${EASYBUILD_INSTALLPATH} --install-latest-eb-release
fi

# If the directory exist and the latest EasyBuild module is there, we simply install the
# software stack which we provide. 
if [ -e ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}* ]; then
	echo "We are installing the software as defined in ${SOFTWARE}"
        cat "${SOFTWARE}"
	# We can execute the container and tell it what to do:
	# IF it is a GPU node, we need to mount /var/log from within the container to a temp-directory outside.
	# If it is not a GPU node, we don't need that
		if [ -n "${NV_FLAG}" ]; then
		   echo "This is a GPU installtion!"
                   singularity exec ${NV_FLAG} --bind ${opencl}::"/etc/OpenCL" --bind ${BINDDIR} --bind ${OPTDIR} \
                   --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} --bind ${EB_TMPDIR}:"/tmp" --userns --overlay ${ovl} \
		   --bind ${PBSHOSTFILE}:${PBSHOSTFILE} ${CONTAINER} ${SOFTWARE}
                else
		   echo "This is a CPU installation"
                   singularity exec --bind ${BINDDIR} --bind ${OPTDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
                   --bind ${EB_TMPDIR}:"/tmp" --bind ${PBSHOSTFILE}:${PBSHOSTFILE} ${CONTAINER} ${SOFTWARE}
                fi
fi

echo "Installation finished at $(date)"


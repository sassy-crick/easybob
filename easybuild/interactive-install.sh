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
# 23/06/2023: Script adapted to HX1, which also means some modularity has been added
#             to run on different clusters

# Where is the script located?
BASEDIR=$(dirname "$0")

# The umask on the nodes is set to 0077 which is causing problems for the software 
# installation, so we need to change that:
umask 0022

# Some defaults which we get from the site-config environment file
# That is specific to the cluster we are using the script
# This is only a stepping stone until we got all of the hardware on CX3 in
# the new OS!

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
        ;;
        *)
        echo -e "\e[1;31mNo site-config file was found. Stopping here\e[0m"
        exit 2
esac

echo 'Installing software on Cluster' ${cluster}

source ${BASEDIR}/../${SITECONFIG}

# We need to know which architecture we are running on.
# Right now, that happens at submission time

if [ -n "$1" ]; then 
        ARCH="$1"
        export ARCH=${ARCH}
        export APPTAINERENV_PS1="${ARCH} on [\u@\h \W]\$ "
else
        echo "No architecture was defined, so we are stopping here!"
        exit 2
fi

# In case we are doing a dev(elop) installation, we need to override the PREFIX, EASYBUILD_OPTARCH and 
# INSTALLPATH for EasyBuild

if [[ ${ARCH} == "dev" ]] || [[ ${ARCH} == "develop" ]]; then
	echo "We are installing the software in the development software stack"
	dev
	export ARCH="dev"
	echo "We are using ${EASYBUILD_TMPDIR} as tempdir for EasyBuild"
        export APPTAINERENV_PS1="${ARCH} on [\u@\h \W]\$ "
fi

# In case we are doing a noarch installation, we need to override the PREFIX, EASYBUILD_OPTARCH and 
# INSTALLPATH for EasyBuild

if [[ ${ARCH} == "noarch" ]]; then
        echo "We are installing the software in the noarch software stack"
        noarch
        export ARCH="noarch"
        EASYBUILD_TMPDIR="/dev/shm/$USER"
        echo "We are using ${EASYBUILD_TMPDIR} as tempdir for EasyBuild"
        export APPTAINERENV_PS1="${ARCH} on [\u@\h \W]\$ "
fi

# In case we are doing a CPU installation manually, we need to override the PREFIX, and 
# INSTALLPATH for EasyBuild

if [[ ${ARCH} == "icelake" ]]; then
        echo "We are installing the software in the icelake software stack"
        icelake 
        export ARCH="icelake"
        EASYBUILD_TMPDIR="/dev/shm/$USER"
        echo "We are using ${EASYBUILD_TMPDIR} as tempdir for EasyBuild"
        export APPTAINERENV_PS1="${ARCH} on [\u@\h \W]\$ "
fi
# Some software requires a specific software-group. We simply use the 'newgrp' command for that
# https://wiki.ubuntuusers.de/newgrp/
# This must be set *before* the container is starting. 
# We simply check if NEWGROUP is defined as the second variable. If that is not used, we don't do 
# anything

if [ -n "$2" ]; then
        newgroup="$2"
        echo "Please run the following command first:"
        echo 'newgrp' "$newgroup"
        echo 'And then run the "./interactive-install.sh' "$1"'" command again as printed'
        echo 'Exiting now'
        exit 4
fi

# Setting the environment for EasyBuild inside the container
# The values come from the respective source files and might be changed further down
# for specific environments
export APPTAINERENV_EASYBUILD_ACCEPT_EULA_FOR=${EASYBUILD_ACCEPT_EULA_FOR} 
export APPTAINERENV_EASYBUILD_PREFIX=${EASYBUILD_PREFIX}
export APPTAINERENV_EASYBUILD_SOURCEPATH=${EASYBUILD_SOURCEPATH}
export APPTAINERENV_EASYBUILD_INSTALLPATH=${EASYBUILD_INSTALLPATH}
export APPTAINERENV_EASYBUILD_BUILDPATH=${EASYBUILD_BUILDPATH}
export APPTAINERENV_EASYBUILD_TMPDIR=${EASYBUILD_TMPDIR}
export APPTAINERENV_EASYBUILD_PARALLEL=${CORES}
export APPTAINERENV_EB=${EB}
export APPTAINERENV_MODULEPATH=${MODULEPATH}
export APPTAINERENV_LC_ALL="C.UTF-8"

# We only export OPTARCH if and when it is set!
if [  ${#EASYBUILD_OPTARCH} -gt 0 ]; then
	export APPTAINERENV_EASYBUILD_OPTARCH=${EASYBUILD_OPTARCH}
fi
# Right now we don't have access to /tmp, so we are using our ephemeral instead
EB_TMPDIR="${EPHEMERAL}"

#########################################################################################
# These should not need to be touched
# Future development for EESSI
OVERLAY_BASEDIR="${SOFTWARE_HOME}"
OVERLAY_LOWERDIR="${OVERLAY_BASEDIR}/apps"
OVERLAY_UPPERDIR="/dev/shm/${USER}/upper"
OVERLAY_WORKDIR="/dev/shm/${USER}/work"
# Used for EasyBuild
SOFTWARE_HOME="${EASYBUILD_INSTALLPATH}"
CONTAINER="${CONTAINER_DIR}/${CONTAINER_VERSION}"
SCRIPTS_DIR="${WORKINGDIR}/${ARCH}/${PBS_JOBID}/scripts"
SOFTWARE="${SCRIPTS_DIR}/software.sh"
#########################################################################################

echo "Installation started at $(date)"
# We check if the folders are here, if not we install them
if [ -d ${SOFTWARE_INSTDIR} ]; then
	echo "Making sure all directories exist in $SOFTWARE_INSTDIR/${ARCH} "
	mkdir -p ${SOFTWARE_HOME}
	mkdir -p ${SOFTWARE_INSTDIR}/sources
	mkdir -p ${EASYBUILD_TMPDIR}
	mkdir -p ${EASYBUILD_BUILDPATH}
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

# For the GPU nodes, we need make sure the container is using the allocated GPUs. 
# The allocation is done manually here and we need to set the '--nv' flag
# We are using the CUDA_COMPUTE_CAPABILITIES to check if it is a GPU install or not. 

if [ -n "${CUDA_COMPUTE_CAPABILITIES}" ]; then
	export CUDA_VISIBLE_DEVICES="0,1" # needed as we are working interactively!
	export APPTAINERENV_CUDA_VISIBLE_DEVICES="0,1" # needed for Apptainer
	NV_FLAG="--nv"
	ovl=/dev/shm/overlay_$$
	mkdir -p ${ovl}
else
	NV_FLAG=""
	ovl=/dev/shm/overlay_$$
	mkdir -p ${ovl}
fi

# For the Intel compilers, IMPI is expecting a hostfile in  /var/spool/pbs/aux
# So we need to bind-mount that. 
PBSHOSTFILE="/var/spool/pbs/aux"

# We check if we already have an EasyBuild module file.
# If there is none, we assume it is a fresh installation and so we need
# to upgrade EasyBuild to the latest version first before we can continue
if [ ! -d ${SOFTWARE_HOME}/modules/all/EasyBuild ]; then
	        EBLATEST="eb"
                singularity exec --bind ${BINDDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
                ${CONTAINER} ${EBLATEST} --prefix=${SOFTWARE_HOME} --installpath=${EASYBUILD_INSTALLPATH} --install-latest-eb-release
        elif [ ! -e ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}* ]; then
                echo "We are upgrading EasyBuild to the latest version."
		EBLATEST="eb"
                # We can execute the container and tell it what to do:
                singularity exec --bind ${BINDDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
                ${CONTAINER} ${EBLATEST} --prefix=${SOFTWARE_HOME} --installpath=${EASYBUILD_INSTALLPATH} --install-latest-eb-release
fi

# If the directory exist and the latest EasyBuild module is there, we simply install the
# software stack which we provide. 
if [ -e  ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}* ]; then
	echo "This ${CONTAINER} container is running on ${ARCH}"
	# We can execute the container and tell it what to do:
	singularity shell ${NV_FLAG} --bind ${BINDDIR} --bind ${OPTDIR} --bind ${SOFTWARE_HOME}:${EASYBUILD_INSTALLPATH} \
	--bind ${EB_TMPDIR}:"/tmp" --overlay ${ovl} --bind ${PBSHOSTFILE}:${PBSHOSTFILE} ${CONTAINER} 
 else
	echo "There is a problem"
	ls ${SOFTWARE_HOME}/modules/all/EasyBuild/${EB_VERSION}.lua
	exit 2
fi

#echo "Installation finished at $(date)"


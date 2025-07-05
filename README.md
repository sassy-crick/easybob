# EasyBob, an automatic software installation script




## Introduction:

The aim of the script is to install the software inside a container, and thus the so installed software is independent from the OS as much as possible, and also takes care of different architectures. The idea comes from the EESSI project and how the software is installed in there. So kudos to them!!

The project consist of two components, the front-end and the back-end. 



## How-to front-end:

The folder `frontend` contains the demonstration web front-end for EasyBob. The front-end requires a web-server, php and a `PostgreSQL` database. Furthermore, the information to feed the database are coming from the `EasyConfig` GitHub repository. Ideally, regular download and feeding it into the database could be done via a cron-job for example. 

The folder `logs` contains an example file of such an incremental upload, where the content was pulled on 4.7.2025. 

The folder `new-entry-upload` contains the script `db-upload.sh` for uploading the new content to the database, with `database.ini` containing the information about the database, like username and password. This needs to be changed! Once all set up, usage is simple:

```bash
$ ./db-upload.sh ../logs/04072025.log
```

in the current example. 

The folder `php-scripts` contains the php-scripts which are being used to create the webpage and thus should be copied to the webserver. 

In order to set up the database, the folders `db-initialisation` and `toolchain-module-upload` are reqired. 

You first need to set up the database, which should be done from either files from the ` db-initialisation` folder. The `01072025-full.sql` creates the full database, as of 1.7.2025, the `restore-db-empty.sql` should just create the database. In case you just want to have an empty database, the scripts in the `toolchain-module-upload` need to be executed to add the toolchains and module list. Again, the `database.ini` contains all the information to connect to the database and need to be changed accordingly. 

## How-to back-end:

Before the `automatic-build.sh` script can run, there are a few files which need to be adjusted. 

- `site-config`
- `softwarelist.txt`
- `softwarelist.yaml`

The `site-config` file should contain all relevant paths for the software installation and that should be the only file which needs changes. That said, it might be worth to have a look at the other files to make sure nothing is accidentally hard-coded.

The `automatic-build.sh` script is expecting the files `software.txt` or `software.yaml` in the current directory, which should not be the one where the software is installed. We recommend to set an alias like this for example:
```bash
$ alias easybob=/FULL/PATH/TO/automatic-build.sh
```

This avoids frustration. Either  `software.txt` or `software.yaml`  are enough, the scripts detect which ones are around and acts accordingly. This script is then then submitting the jobs to the queue, with the default being PBSPro, one for each to be build architecture as defined in the `site-config` file. The submission script so generated is then calling the `install.sh` script. 

The `install.sh` does basically the whole magic. There are a few lines at the top which need to be changed to reflect where the software needs to go. It might be worth checking that but most of the relevant stuff is defined in the `site-config` file and are: 

- `SOFTWARE_INSTDIR` which is where the software tree and all the helper stuff lives
- `BINDDIR` is the directory which needs to be bound inside the container as per default Apptainer does only mount `/tmp` and `/home` it seems.

You also might want to look at:

- `CONTAINER_VERSION` which is the name of the sif-file, i.e. the container
- `EB_VERSION` which is the version of EasyBuild to be used for building software. If that does not exist, it should be automatically installed
- `SW_LIST` contains a simple list of the EasyConfig files to be installed. All in one line with a blank between them. You can add common flags like `-d` or `--rebuild` if required, everything else like `--robot` , `--cuda-compatibility`, and `--optarch` are set automatically (see `site-config` for more information). 
- `SW_YAML`contains the software to be installed as an EasyStack file in `yaml` format. 

Right now, the scripts are expecting a GitHub repository of the EasyConfig files, so the latest merged ones can be used. This can be turned off in the `site-config` file if that is not desired. 

Both the `SW_LIST` and the `SW_YAML` are independent from each other. So as long as the file got a content, it will be used. 

The `software.sh` will be created on the fly in the right directory, using the various template files, and  does contain the list of software which needs to be installed which will be pulled in by the `softwarelist.txt` file. The EasyStack file, so it exists, will be places in the correct directory. 
If you need to change any of the paths where the software will be installed, you will need to look into `software.tmpl`, the Singularity Definition file `Singularity.eb-4.9.4-envmod-rocky8.9` and both the `install.sh` and `interactive-install.sh` files. That said, in theory everything should be configured already in the `site-config` file.
Note: You can mount any folder outside the container but you will need to make sure that the `MODULEPATH` variable are identical inside and outside the container. Thus, if you are using like in our example `/sw-eb` as the root install directory, the `MODULEPATH` then needs to be set to for example `/sw-eb/modules/all` inside and outside the container!

The first time the script runs, it will create the directory structure but then stops as the Apptainer container is not in place.

Once the container in the right folder we are upgrading EasyBuild to the latest version. This way, a module file is created automatically. Once that is done, the software will be installed if required.  

## Hooks

In order to make sure that licensed software has the right permissions, there is a site-specific file in the `hooks` directory calle `site-hooks.py` Depending on when to run, several parameters can be changed. That makes sense to for example restrict access to a specific folder by means of setting the group and the permissions, but also makes sense when building software which depends on the presence or absence of specific networks for example. 

## GPU builds

For the GPU nodes, the command line flag `--cuda-compute-capabilities=8.0` for the A100 GPU or `--cuda-compute-capabilities=7.5` for the RTX600 GPU is defined in the `site-config` file and the script automatically detects if the EasyConfig filename contains `cuda`, either in lower cases or upper cases. This software will only be build on the GPU nodes automatically. Both the `interactive-install.sh` and the `install.sh` script are using the `--nv` flag which is needed for the GPU builds.

## Requirements:

`Apptainer` >= 1.3.6

## Flowchart
This flowchart hopefully illustrates the interaction of the different components. Most importantly is the `site-config` file as this is where all the relevant information of the used cluster is sitting.
```mermaid
flowchart TD;
A(automatic-build.sh)-->|creates and submits for each architecture|B[jobscript];
B[jobscript]-->|executes|C[install.sh];
D[(site-config)]-->|pulls in|C{install.sh};
E[software-head.tmpl]-->C{install.sh};
F[software-list.tmpl]-->C{install.sh};
G[software-bottom.tmpl]-->C{install.sh};
C[install.sh]-->|1|H[executes installation with EB];
H[executes installation with EB]-->|2|C[install.sh];
C[install.sh]-->|3|I[executes testing with EB];
J[EB hooks]-->H[executes installation with EB];
J[EB hooks]-->I[executes testing with EB];
k[sw-groups]-->C{install.sh};
```



## To Do:

The code is working well but with all code there is room for improvement, or bugs which have yet to be found. Please report any bugs, issues or comments.

Right now, the templates are geared towards PBSPro, but the relevant sections in the `automatic-build.sh` file should be easy to update to for example `SLURM`. 




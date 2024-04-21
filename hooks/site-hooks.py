# Site-specific installation hooks for EasyBuild 
# Some inspiration are from here:
# https://github.com/easybuilders/easybuild-framework/blob/develop/contrib/hooks/hpc2n_hooks.py
# Some suggested hooks are mentioned here but the list is by no means complete

import os
import easybuild.tools.environment as env

from distutils.version import LooseVersion
from easybuild.framework.easyconfig.format.format import DEPENDENCY_PARAMETERS
from easybuild.tools.filetools import apply_regex_substitutions
from easybuild.tools.build_log import EasyBuildError
from easybuild.tools.modules import get_software_root
from easybuild.tools.systemtools import get_shared_lib_ext
from easybuild.tools.run import check_async_cmd, run_cmd

# Section for specific software configuration requirements (post_source_hooks)

def post_source_hook(self, *args,**kwargs):

def parse_hook(ec, *args, **kwargs):

def pre_configure_hook(self, *args, **kwargs):

def pre_prepare_hook(self, *args, **kwargs):

def module_write_hook(self, *args, **kwargs):

def post_permissions_hook(self, *args, **kwargs):


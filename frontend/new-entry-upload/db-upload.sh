#!/usr/bin/env bash
# script to filter out new EC files
#
# Loading EasyBuild
. /etc/profile.d/lmod.sh 
ml EasyBuild
eb --version

# checking if a string is a number, or not
# We do that via a function from here:
# https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash

isnum_Regx() { [[ $1 =~ ^[+-]?([0-9]+([.][0-9]*)?|\.[0-9]+)$ ]] ;}

# Using Python to query EasyBuild for the content of the EasyConfig file.
# Thanks to Bard Oldman for providing this.

function EC  {
python3 <<EOF
import sys
from easybuild.framework.easyconfig.parser import EasyConfigParser
import psycopg2
from config import load_config

# Inserting the various variables into the various tables. 
# This can and should be done better but that is working it seems

def insert_sw_version(sw_version):
    """ Insert a new Software Version into the sw_version table """

    sql = """insert into sw_version (sw_version) 
             VALUES(%s) ON conflict (sw_version) do nothing returning id;"""
    
    sw_version_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (version,))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    sw_version_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return sw_version_id
        print(sw_version_id)

def insert_toolchain(toolchain):
    """ Insert a new Toolchain into the toolchain table.
        This might not be needed but in case there is a newer version out. """

    sql = """insert into toolchain (toolchain) 
             VALUES(%s) ON conflict (toolchain) do nothing returning id;"""
    
    toolchain_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (toolchain,))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    toolchain_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return toolchain_id
        print(id)

def insert_toolchain_version(toolchain_version):
    """ Insert a new Toolchain Version into the toolchain_version table """

    sql = """insert into toolchain_version (toolchain_version) 
             VALUES(%s) ON conflict (toolchain_version) do nothing returning id;"""
    
    toolchain_version_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (toolchain_version,))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    toolchain_version_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return toolchain_version_id
        print(id)

def insert_sw_name(name,description,citation,homepage):
    """ Insert a new Software into the sw_name table """

    sql = """insert into sw_name (sw_name,sw_description,sw_cite,sw_url) 
             VALUES(%s,%s,%s,%s) ON conflict (sw_name) do nothing returning id;""" 
    
    sw_name_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (name,description,citation,homepage))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    sw_name_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return sw_name_id
        print(id)

def insert_ec_name(ec_name,name,version,toolchain,toolchainversion,module):
    """ Insert a new EC name into the ec_name table. """

    sql = """insert into ec_name (ec_name,sw_name_id,sw_version_id,toolchain_id,toolchain_version_id,module_id) 
             VALUES(%s,
	     (select id from sw_name where sw_name=%s),
             (select id from sw_version where sw_version=%s),
             (select id from toolchain where toolchain=%s),
             (select id from toolchain_version where toolchain_version=%s),
             (select id from module where module=%s))
             ON conflict (ec_name) do nothing returning ec_id;"""
    
    ec_name_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (ec_name,name,version,toolchain,toolchainversion,module))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    ec_name_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return ec_name_id



##
# Getting the values from the EasyConfig file. 
# Code is courtesy of Bart Oldman
##
ecp = EasyConfigParser("$ec")
name = ecp.get_config_dict()['name']
version = ecp.get_config_dict()['version']
homepage = ecp.get_config_dict()['homepage']
description = ecp.get_config_dict()['description']
citation = ecp.get_config_dict().get("citing", "")
toolchain = ecp.get_config_dict()['toolchain']['name']
toolchainversion = ecp.get_config_dict()['toolchain']['version']
module = ecp.get_config_dict()['moduleclass']

# Inserting the software name, description, citiation and homepage in the sw_name table:
if __name__ == '__main__':
    insert_sw_name(name,description,citation,homepage)

# Inserting the software-version in the sw_version table:
if __name__ == '__main__':
    insert_sw_version(version)

# Inserting any new toolchains in the toolchain table:
if __name__ == '__main__':
    insert_toolchain(toolchain)

# Inserting any new toolchain versions in the toolchain_version table:
if __name__ == '__main__':
    insert_toolchain_version(toolchainversion)

# Combining the 4 altered tables plus the more statis module table into one master table
# to rule them all:
ec_name = "$ec_name"
if __name__ == '__main__':
    insert_ec_name(ec_name,name,version,toolchain,toolchainversion,module)

# For logging purposes
print (ec_name)

EOF
}

# Sorting the GitHub output list so we only get the new EasyConfig file, no patches

rm -f /dev/shm/ec-list

cat $1 | grep -v patch | awk -F "/" '/create/  {print $NF}' >> /dev/shm/ec-list
cat $1 | grep -v patch | awk -F "/" '/rename/  {print $NF}' | awk -F ' ' '{print $(NF-1);}' | awk -F '}' '{print $(NF-1);}'>> /dev/shm/ec-list

# creating the path of where to find the EasyConfig file.
# This needs to be done in a loop
for ec_name in $(cat /dev/shm/ec-list); do
	# First we find the name of the software. That could be a single word, or two-words. 
	# As the pattern is: softwarename-version-toolchain-toolchainversion.eb, we use a simple awk command for that
	# However, somtimes we got software-name-version-toolchain-toolchainversion.eb, so we need to check for that as well
	# This is where the function isnum_Regx comes in handy
	sw=$(echo $ec_name | awk -F "-" '{print $2}' | cut -b1 )
	if isnum_Regx "$sw"; then 
		sw_name=$(echo $ec_name | awk -F "-" '{print $1}')
	else
		sw_name=$(echo $ec_name | awk -F "-" '{print $1"-"$2}')
	fi
	# now we get the first letter of that name
	sw_name_letter=$(echo $sw_name | cut -b 1 | awk '{print tolower($0)}') 
	path='/PATH/TO/git/easybuild-easyconfigs/easybuild/easyconfigs/'$sw_name_letter'/'$sw_name
	echo 'Path is' $path
	ec=$path'/'$ec_name
	echo $ec
	if [ -s ${ec} ]; then
		EC 
	fi
done



#!/bin/bash
# script to add toolchains to database
#

# Loading Easybuild
. /etc/profile.d/lmod.sh 
ml EasyBuild &> /dev/null

tn=$(eb --list-toolchains | tail -n+2 | awk -F ':' '{print $1}' | awk -F ' ' '{print $NF}')

echo $tn

for i in $(echo $tn); do
echo "Inserting $i in toolchain"

python3 <<EOF
import psycopg2
from config import load_config


def insert_toolchain(toolchain_name):
    """ Insert a new toolchain into the toolchain table """

    sql = """INSERT INTO toolchain(toolchain)
             VALUES(%s) RETURNING id;"""
    
    ec_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (toolchain_name,))

                # get the generated id back                
                rows = cur.fetchone()
                if rows:
                    vendor_id = rows[0]

                # commit the changes to the database
                conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)   

    finally:
        return ec_id


if __name__ == '__main__':
    insert_toolchain("$i")

EOF
done



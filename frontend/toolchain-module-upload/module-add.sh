#!/bin/bash
# script to add module to database
#

# Loading Easybuild
. /etc/profile.d/lmod.sh 
ml EasyBuild &> /dev/null

mn=$(eb --show-default-moduleclasses| tail -n+3 | awk -F ':' '{print $1}' | awk -F ' ' '{print $NF}')

echo $mn

for i in $(echo $mn); do
echo "Inserting $i in module"

python3 <<EOF
import psycopg2
from config import load_config


def insert_module(module):
    """ Insert a new toolchain into the module table """

    sql = """INSERT INTO module(module)
             VALUES(%s) RETURNING id;"""
    
    ec_id = None
    config = load_config()

    try:
        with  psycopg2.connect(**config) as conn:
            with  conn.cursor() as cur:
                # execute the INSERT statement
                cur.execute(sql, (module,))

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
    insert_module("$i")

EOF
done



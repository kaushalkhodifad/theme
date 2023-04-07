import os, sys
script_path = os.path.realpath(os.path.dirname(__name__))
os.chdir(script_path)
sys.path.append("/home/analytics-user/")
sys.path.append("/home/analytics-user/master_files/")
from os import name
from sqlalchemy import create_engine
from sqlalchemy.sql import text
from sqlalchemy.exc import SQLAlchemyError
import pandas as pd
from sqlalchemy.sql.expression import false
import datetime
import json
# from db_details import *
from db_credentials import *

def main():
    try:
        optimus_db_string = "postgresql://"+optimus["user_name"]+":"+optimus["password"]+"@"+optimus["host"]+":"+optimus["port"]+"/"+optimus["name"]
        optimus_db_connection = create_engine(optimus_db_string)
        # print(optimus_db_connection)
        with optimus_db_connection.connect() as con:
            # Select statement
            file = open("git_projects/theme/theme.sql")
            query = text(file.read())
            result_set =con.execute(query)
            hourly_data_df = pd.DataFrame(result_set.fetchall())
            hourly_data_df.columns = result_set.keys()
            con.close()
        
        optimus_db_connection.dispose()

        print("# records ::: ", hourly_data_df.shape,", file name::",os.path.basename(__file__).split(".")[0] ,", time of execution ::" ,datetime.datetime.now(), "prod test")
        # analytics_db_string = "postgresql://"+analytics_db_local["user_name"]+":"+analytics_db_local["password"]+"@"+analytics_db_local["host"]+":"+analytics_db_local["port"]+"/"+analytics_db_local["name"]
        analytics_db_string = "postgresql://"+analytics_db["user_name"]+":"+analytics_db["password"]+"@"+analytics_db["host"]+":"+analytics_db["port"]+"/"+analytics_db["name"]
        analytics_db_connection = create_engine(analytics_db_string)
        
        with analytics_db_connection.connect() as con:
            file = open("git_projects/theme/delete_theme.sql")
            query = text(file.read())
            con.execute(query)
            con.close()


        
        hourly_data_df.to_sql(name="theme", con=analytics_db_connection, schema="tableau_schedules", if_exists="replace", index=false)
        
        analytics_db_connection.dispose()
        return {"status":"success"}
    except Exception as e:
        return {"status":"failed","error_desc":str(e)}

if __name__ == "__main__":
    main()

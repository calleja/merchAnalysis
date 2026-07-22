'''
establish and return an sqlalchemy engine object to a target db (options: local or droplet)

will instatiate the Credentials class from contaainer_credentials to obtain 
the most relevant credentials based on the calling machine (my macbook, etc)
'''


import sqlalchemy
from container_credentials import Credentials #the class is Credentials

#being lazy and posting the credentials for the droplet db here as opposed to amending container_credentials.py
#using ssh port forwarding

database = 'membership_ard'
def get_connection():
	return sqlalchemy.create_engine(
		url="mysql+pymysql://{0}:{1}@{2}:{3}/{4}".format(
			user, password, host, port, database
		)
	)

class DatabaseConnection:
    def __init__(self, target = None):
        self.target = target
        self.engine = get_connection()
		
    if __name__ == '__main__':

	try:
	
		# GET THE CONNECTION OBJECT (ENGINE) FOR THE DATABASE
		engine = get_connection()
		print(
			f"Connection to the {host} for user {user} created successfully.")
	except Exception as ex:
		print("Connection could not be made due to the following error: \n", ex)
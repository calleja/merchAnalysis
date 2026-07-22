#!/usr/bin/env python
# coding: utf-8

# In[8]:


#create a map of docker container credentials by system name
import platform

class Credentials:

    # target db credentials; contains local db and droplet db
    credentials_map = {
    'mofongo':{'user':'root','pass':'salmon01','database':'membership','port':3306,'host':'172.17.0.2'},
    'candela':{'user':'root','pass':'salmon01','database':'membership','port':3306,'host':'172.17.0.2'},
    'membership_ard':{'user':'lcalleja','pass':'salmon01','host':'100.102.223.21','port':3306,'database':'membership_ard'},
    'radish':{'user':'lcalleja2','password':'3059891242','host':'127.0.0.1','port':5433,'database':'membership_ard'},
    'casita':{}
    }
    '''
    user = 'lcalleja2'
    password = '3059891242'
    host = '127.0.0.1' #tailscale IP address 100.102.223.21 for the radish server/droplet
    port = 5433
    '''
    comp_name = platform.node()

    def get_credentils_map(self):
        return(Credentials.credentials_map)
    
    def retrieve_credentials(self,server_override):
        if server_override is None: #default to the computer credentials retrieved from the platform package
            if 'candela' in Credentials.comp_name:
                treated_name = 'candela'
        
            elif 'mofongo' in Credentials.comp_name:
                treated_name = 'mofongo'
            elif 'luis' in Credentials.comp_name:
                treated_name = 'luisito'    

            return Credentials.credentials_map[treated_name]
               
        else:
            treated_name = server_override
            return Credentials.credentials_map[treated_name]
    


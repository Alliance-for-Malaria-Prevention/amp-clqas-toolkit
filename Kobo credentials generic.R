
#
# Kobo credentials
#

# To download data directly from the server, you will need to enter your credentials below. These are your personal password/token so should not be shared widely.

# Option 1: get token through Kobo's web interface and paste it here
kobo_setup(url = "https://kf.kobotoolbox.org",
           token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") # Replace this with the token 

# Option 2: get token through R
my_token <- kobo_token(username = "yourusername", # Replace with your Kobo user name
                       password = "password123", # Replace with your Kobo password
                       overwrite = TRUE)

kobo_setup(url = "https://kf.kobotoolbox.org",
           token = my_token)






# Get tokens for Bitmoji servers calls
#
# IAMSENSORIA.COM BLOG - SOURCE CODE
from helpers import *

myBit = Bitmojier("your_email@example.com", "your_password_here")
token = myBit.login()
print("My authentication token is: " + token)

avatar_id =myBit.get_avatar_id(token)
print("My avatar ID is: " + avatar_id)

get_my_images(token)
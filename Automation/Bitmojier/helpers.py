# Get tokens for Bitmoji servers calls
#
# IAMSENSORIA.COM BLOG - SOURCE CODE
#
import requests
import json
import os
import os.path

class Bitmojier():
    """docstring for Bitmojier"""
    def __init__(self, username, password):
        self.username = username
        self.password = password

    def login(self):

        headers = {
          'Referer': 'https://www.bitmoji.com/account_v2/',
          'Host': 'api.bitmoji.com',
          'Origin': 'https://www.bitmoji.com',
          'Content-Type': 'application/x-www-form-urlencoded'
        }
        
        payload = 'client_id=imoji&username=' + self.username +'&password=' + self.password + '&client_secret=secret&grant_type=password'

        r = requests.post(
            "https://api.bitmoji.com/user/login",
            headers=headers,
            data=payload,
        )

        # print(r.text.encode('utf8'))
        r.raise_for_status()
        response = r.json()
        return response['access_token']

    def get_avatar_id(self, token):
        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/48.0.2564.116 Chrome/48.0.2564.116 Safari/537.36",
            "Content-Type": "application/json",
            "Cookie": "bitmoji_bsauth_token=" + token,
            "bitmoji-token": token,
        }
        r = requests.get("https://api.bitmoji.com/user/avatar", headers=headers)
        r.raise_for_status()
        return r.json()['id']

    def get_my_images(images):
        images_dir = os.path.join(os.getcwd(), "e")
        if not os.path.exists(images_dir):
            os.makedirs(images_dir)

        for image in images:
            try:
                image_path = os.path.join(images_dir, "%s.png" % image['template_id'])
                if not os.path.exists(image_path):
                    r = requests.get(image['src'])
                    with open(image_path, "wb") as f:
                        for chunk in r.iter_content(chunk_size=4096):
                            if chunk:
                                f.write(chunk)

            except:
                traceback.print_exc()

            if os.path.exists(image_path):
                image['original_src'] = image['src']
                image['src'] = 'e/%s.png' % image['template_id']

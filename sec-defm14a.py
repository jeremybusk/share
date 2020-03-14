#!/usr/bin/env python3
# pip3 install requests bs4
import subprocess
from bs4 import BeautifulSoup as bs
import requests
import re
import sys
import time
import os

def main():
    get_index()

def get_index():
    downloads_dir = 'downloads'
    if not os.path.exists(downloads_dir):
        os.makedirs(downloads_dir)

    with open('./index.html', 'r') as f:
        html_page = f.read()
    soup = bs(html_page, 'html.parser')

    count = 0
    for a in soup.findAll('a'):
        href = a.get('href')
        # Document/Search/?formType=FormDEFM14A
        # /Document/Header/?formType=DEFM14A
        if 'Document' in href and 'DEFM14A' not in href and 'https://sec.report/Document/' not in href:
            url = f"https://sec.report/{href}"
            filename = url.split('/')[-2] + '.html'
            filename = f"{downloads_dir}/{filename}"
            count += 1
            print(f"{count} url: {url} filename: {filename}")
            print(count)
            curl(url, filename)

def curl(url, filename):
    url = "https://sec.report//Document/0001193125-20-071574/"
    cmd = f"curl {url} > {filename}"
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    print(stdout)

if __name__ == "__main__":
    main()



# TRASH
#
        # wlist = ["Document", "DEFM14A", "sec.report"]
    # args = shlex.split(cmd)
#             # r = requests.get(url)
#             # save_file = "fff.html"
#             # open(save_file, 'wb').write(r.content)

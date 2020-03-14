#!/usr/bin/env python3
import subprocess
from bs4 import BeautifulSoup as bs
# import requests
import re
import os
import sys


def main():
    get_forms()


def get_forms():
    downloads_dir = 'downloads'
    if not os.path.exists(downloads_dir):
        os.makedirs(downloads_dir)
    pages = range(55)
    for page in pages:
        print(page)
        filename = f'{page}.html'
        index_url = f"https://sec.report/Document/Header/?formType=DEFM14A&page={page}"
        curl(index_url, filename)
        # with open(f'./{filename}', 'r') as f:
        with open(filename, 'r') as f:
            html_page = f.read()
        soup = bs(html_page, 'html.parser')

        count = 0
        for a in soup.findAll('a'):
            href = a.get('href')
            # Document/Search/?formType=FormDEFM14A
            # /Document/Header/?formType=DEFM14A
            if 'Document' in href and 'DEFM14A' not in href and 'sec.report' not in href:
                url = f"https://sec.report/{href}"
                filename = url.split('/')[-2] + '.html'
                filename = f"{downloads_dir}/{filename}"
                count += 1
                print(f"{count} url: {url} filename: {filename}")
                curl(url, filename)



def curl(url, filename):
    # cmd = f"curl {url} > {filename}"
    cmd = f"curl -o {filename} {url}"
    # cmd = shlex.split(cmd)
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    print(stdout)


if __name__ == "__main__":
    main()

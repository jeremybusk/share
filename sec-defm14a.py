#!/usr/bin/env python3
from bs4 import BeautifulSoup, SoupStrainer
import httplib2
import sys
import re
import subprocess
import os


def main():
    filename = 'urls.txt'
    downloads_dir = 'downloads'
    if not os.path.exists(downloads_dir):
        os.makedirs(downloads_dir)
    http = httplib2.Http()
    pages = range(55)
    url_list = []
    open(filename, 'w').close()
    for page in pages:
        index_url = f"https://sec.report/Document/Header/?formType=DEFM14A&page={page}"

        status, response = http.request(index_url)

        p1 = re.compile('/Document/(\d{10}-\d{2}-\d{6}/)')
        p2 = re.compile('(\d{10}-\d{2}-\d{6})')
        for link in BeautifulSoup(response, features="html.parser", parse_only=SoupStrainer('a')):
            if link.has_attr('href'):
                href = link['href']
                m = p1.search(link['href'])
                if m:
                    url_path = m[0]
                    if len(url_path) != 0:
                        url = f"https://sec.report/{url_path}"
                        url_list.append(url)

    with open('all-urls.txt', 'w') as f:
        for url in url_list:
            f.write(f"{url}\n")

    url_list = list(set(url_list))  # unique the list

    with open(filename, 'w') as f:
        for url in url_list:
            doc_uid = p2.search(url)[0]
            html_file = f"{downloads_dir}/{doc_uid}.html"
            curl(url, html_file)
            f.write(f"{url}\n")


def curl(url, filename):
    print(url)
    print(filename)
    cmd = f"curl -o {filename} {url}"
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    print(stdout)


if __name__ == "__main__":
    main()


# cmd = shlex.split(cmd)
# f.write(url)
# # open(filename, 'w').close()
# f = open(filename, 'a')
# f.close()





# TRASH
# list(set(output))
#     for url in url_list:
#         if url not in url_list:
#             url_list.append(url)
#
# s = '/Document/0000912057-00-002073/'
# # p = re.compile('ab*')
# # p = re.compile('/Document/[0-9]10*')
# p = re.compile('/Document/(\d{10}-\d{2}-\d{6}/)')
# # p = re.compile('ab*', re.IGNORECASE)
# m = p.search(s)
# print(m[0])
# status, response = http.request('http://www.nytimes.com')


    # filename = f'{page}.html'
# sys.exit()

# status, response = http.request('https://sec.report/Document/Header/?formType=DEFM14A&page=1')
#     pages = range(55)
#     for page in pages:
#         print(page)
#         filename = f'{page}.html'
#         index_url = f"https://sec.report/Document/Header/?formType=DEFM14A&page={page}"

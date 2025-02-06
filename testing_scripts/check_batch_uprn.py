import requests
import os

endpoint = 'http://localhost:9081'
username = 'user'
password = 'password'
filepath = './'
filename = 'test_in.txt'
processed_filename = 'test_out.txt'

upload_url = f'{endpoint}/api2/fileupload2'
download_url = f'{endpoint}/api2/filedownload2?filename={filename}'

# Test upload
with open(os.path.join(filepath, filename), 'rb') as f:
    files = {'file': (filename, f, 'text/plain')}
    r = requests.post(upload_url, files=files, auth=(username, password))
print(r.text)
print(r.status_code)
assert r.status_code == 201

# Test download of processed file
r = requests.get(download_url, auth=(username, password))
with open(os.path.join(filepath, processed_filename), "w") as f:
    f.write(r.text)
print(r.status_code)
assert r.status_code == 200

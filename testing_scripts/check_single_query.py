import requests
import json

endpoint = 'http://localhost:9081'
username = 'user'
password = 'password'

# Testing address
address_string = 'Swansea University,Swansea,SA2 8PP'.replace(' ', '+')
address_uprn = '10010023401'

address_query_url = f'{endpoint}/api2/getinfo?adrec={address_string}'
uprn_query_url = f'{endpoint}/api2/getuprn?uprn={address_uprn}'

# Test UPRN lookup via address string
r = requests.get(address_query_url, auth=(username, password))
print(r.text)
assert r.status_code == 200
assert(json.loads(r.text)['BestMatch']['UPRN'] == address_uprn)

# Test address lookup via UPRN string
r = requests.get(uprn_query_url, auth=(username, password))
print(r.text)
assert r.status_code == 200
assert(json.loads(r.text)['UPRN'] == address_uprn)
#!/usr/bin/env python3.9
import random
import string
import time
import sys


def randomword(length):
   letters = string.ascii_lowercase
   return ''.join(random.choice(letters) for i in range(length))

def memcached(n):
    from pymemcache.client import base

    client = base.Client(("127.0.0.1", 19999))

    mykeys = []
    for x in range(n):
        key = randomword(10)
        client.set(key, str(x))
        mykeys.append(key)
        time.sleep(0.01)

    for k in mykeys:
        client.get(key)
        time.sleep(0.01)

def redis(n):
    import redis
    client = redis.Redis(host="127.0.0.1", port=19999, decode_responses=True)
    mykeys = []
    for x in range(n):
        key = randomword(10)
        client.set(key, str(x))
        mykeys.append(key)
        time.sleep(0.01)

    for k in mykeys:
        client.get(key)
        time.sleep(0.01)

def request_n(n):
    import requests
    for x in range(n):
        r = requests.get('http://127.0.0.1:19999/index.html')
        time.sleep(1)

if __name__ == "__main__":
    if sys.argv[1] == "redis":
        redis(int(sys.argv[2]))
    elif sys.argv[1] == "memcached":
        memcached(int(sys.argv[2]))
    elif sys.argv[1] == "lighttpd":
        request_n(int(sys.argv[2]))
    elif sys.argv[1] == "nginx":
        request_n(int(sys.argv[2]))
    elif sys.argv[1] == "sqlite":
        pass

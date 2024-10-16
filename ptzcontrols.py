#!/usr/bin/python3

import requests
import sys
import os
import json

config = {}

def ptz(direction, count=1):
    site = os.environ["PTZ_SITE"]
    testing = os.environ["PTZ_TESTING"]

    if testing.lower() == "true":
        testing = True
    else:
        testing = False

    reply = ""

    if direction == "l":
        dir = "left"
    elif direction == "r":
        dir = "right"
    elif direction == "d":
        dir = "down"
    elif direction == "u":
        dir = "up"
    else:
        return "ERROR: Invalid direction: {direction}"

    for e in range(0, count):
        url = f"http://{site}/cgi-bin/hi3510/ptz{dir}.cgi"

        if testing == False:
            requests.get(url)
        else:
            reply += f"Test enabled, no request sent, would have sent to: {url}\n"

    reply += f"Success, moved {dir}!"
    return reply

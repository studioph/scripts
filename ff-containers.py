#!/usr/bin/env python3

import argparse
import csv
import json
import pathlib
from dataclasses import dataclass

colors = ["blue", "turquoise", "green", "yellow", "orange", "red", "pink", "purple"]
icons = [
    "fingerprint",
    "briefcase",
    "dollar",
    "cart",
    "vacation",
    "gift",
    "food",
    "fruit",
    "pet",
    "tree",
    "chill",
    "circle",
    "fence",
]


@dataclass
class Proxy:
    internal_ip: str
    external_ip: str
    hostname: str
    city: str
    country: str
    isp: str


parser = argparse.ArgumentParser()
parser.add_argument(
    "--proxies-file",
    type=pathlib.Path,
    required=True,
    help="Path to csv proxy data file",
)
parser.add_argument(
    "--containers-file",
    type=pathlib.Path,
    required=True,
    help="Path to Firefox containers json file",
)
parser.add_argument(
    "--start-id", type=int, default=6, help="The context id to start with"
)
args = parser.parse_args()

with args.proxies_file.open("r", encoding="utf8") as csv_file:
    reader = csv.DictReader(csv_file)
    proxies = [Proxy(**row) for row in reader]

with args.containers_file.open("r", encoding="utf8") as json_file:
    container_data = json.load(json_file)
    containers = container_data["identities"]


def add_container(context_id: int, proxy: Proxy):
    icon = "circle" if proxy.country == "USA" else "vacation"
    color = colors[context_id % len(colors)]
    ip_parts = proxy.internal_ip.split(".")
    entry = {
        "userContextId": context_id,
        "public": True,
        "icon": icon,
        "color": color,
        "name": f"Proxy {ip_parts[2]}-{ip_parts[3]}",
        "accessKey": "",
    }
    containers.append(entry)


context_id = args.start_id

for proxy in proxies:
    add_container(context_id, proxy)
    context_id += 1

with args.containers_file.open("w", encoding="utf8") as json_file:
    json.dump(container_data, json_file)

#!/usr/bin/env python

from __future__ import print_function, unicode_literals

# built-in packages
from argparse import ArgumentParser
import sys
import socket
import json

# installed packages
import requests
import netifaces as ni


ROOT_API = 'https://dns.api.gandi.net/api/v5'


def get_local_ip(opts):
    if opts.interface is None:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect((opts.loc_ip_server, opts.loc_ip_port))
            return s.getsockname()[0]
        except Exception:
            print('[error] couldn\'t connect to socket', file=sys.stderr)
            sys.exit(1)
        finally:
            s.close()
    else:
        try:
            return get_all_ip_interfaces()[opts.interface]
        except KeyError:
            print('[error] interface {} not found'.format(opts.interface),
                  file=sys.stderr)
            sys.exit(1)


def get_all_ip_interfaces():
    interfaces = {
        interface: ni.ifaddresses(interface) for interface in ni.interfaces()
    }

    ips = {
        interface: ifaddress[ni.AF_INET][0].get('addr', None)
        for interface, ifaddress in interfaces.items()
        if ni.AF_INET in ifaddress and len(ifaddress[ni.AF_INET][0]) > 0
    }
    return ips


def get_remote_ip(opts):
    """ Get external IP """

    # Could be any service that just gives us a simple
    # raw ASCII IP address (not HTML etc)
    ip_req = requests.get(opts.ext_ip_server)
    ip_req.raise_for_status()

    return ip_req.text.strip()


def update_ip(new_ip, opts):
    config_url = (
        '{root}/domains/{uuid}/records'
        ''.format(root=ROOT_API, uuid=opts.domain_name)
    )

    config_resp = requests.get(
        config_url, headers={'X-Api-Key': opts.production_key}
    )

    # raise error if 4xx or 5xx
    config_resp.raise_for_status()

    # get the response
    config = config_resp.json()

    a_config = None
    for entry in config:
        if entry['rrset_type'] == 'A' and entry['rrset_name'] == opts.a_name:
            a_config = entry

    if a_config is not None:
        rrset_values = set(a_config['rrset_values'])
        if new_ip in rrset_values and not(opts.force):
            print(
                '[info] A record for "{type}" matches curent ip "{ip}"; '
                'no changes needed.'
                ''.format(type=opts.a_name, ip=new_ip)
            )
            return False
        else:
            delete_url = (
                '{root}/domains/{uuid}/records/{name}/A'
                ''.format(
                    root=ROOT_API,
                    uuid=opts.domain_name,
                    name=opts.a_name
                )
            )
            delete_resp = requests.delete(
                delete_url,
                headers={
                    'Content-Type': 'application/json',
                    'X-Api-Key': opts.production_key
                },
                data='{}'
            )
            delete_resp.raise_for_status()

            print(
                '[info] Deleted previous value{plural} "{ip}"" '
                'for A record "{type}".'
                ''.format(
                    type=opts.a_name,
                    plural=('s' if len(rrset_values) > 1 else ''),
                    ip=','.join(rrset_values)
                )
            )

    update_req_content = {
        'rrset_name': opts.a_name,
        'rrset_type': 'A',
        'rrset_ttl': opts.ttl,
        'rrset_values': [new_ip]
    }

    update_resp = requests.post(
        config_url,
        headers={
            'Content-Type': 'application/json',
            'X-Api-Key': opts.production_key
        },
        data=json.dumps(update_req_content)
    )

    update_resp.raise_for_status()

    print(
        '[info] Set A record "{type}" to new ip "{ip}".'
        ''.format(type=opts.a_name, ip=new_ip)
    )

    return True


def main():
    ap = ArgumentParser()
    ap.add_argument('-k', '--production-key', default=None)
    ap.add_argument('-d', '--domain-name', default=None)
    ap.add_argument('-a', '--a-name', default=None)
    ap.add_argument(
        '-m', '--mode', default='remote', choices=['remote', 'local']
    )
    ap.add_argument('-t', '--ttl', default=300, type=int)
    ap.add_argument('-i', '--ext-ip-server',
                    default='https://ipecho.net/plain')
    ap.add_argument('-l', '--loc-ip-server', default='google.com')
    ap.add_argument('-I', '--interface', default=None)
    ap.add_argument('-f', '--force', action='store_true')
    ap.add_argument('-p', '--loc-ip-port', default=80, type=int)
    ap.add_argument('-L', '--list-interfaces', action='store_true')
    opts = ap.parse_args()

    if opts.list_interfaces:
        interfaces = get_all_ip_interfaces()
        print('\n'.join('{}: {}'.format(*e) for e in interfaces.items()))
        return

    if opts.production_key is None:
        msg = 'No production key provided'
        raise RuntimeError(msg)

    if opts.domain_name is None:
        msg = 'No domain name provided'
        raise RuntimeError(msg)

    if opts.a_name is None:
        msg = 'No A name provided'
        raise RuntimeError(msg)

    if opts.mode == 'remote':
        current_ip = get_remote_ip(opts)
    else:
        current_ip = get_local_ip(opts)

    update_ip(current_ip.strip(), opts)


if __name__ == '__main__':
    main()


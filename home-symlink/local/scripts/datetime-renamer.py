#!/usr/bin/env python2

import os
import sys
from datetime import datetime

def datetime_renamer(path):
    cnt = 0
    for root, dirs, files in os.walk(path):
        names = {}
        for fn in (os.path.join(root, fn) for fn in files):
            if os.path.split(fn)[1].find('.') == 0:
                continue
            creation = datetime.fromtimestamp((os.path.getmtime(fn)))
            ext =  os.path.splitext(fn)[1].lower()
            name = creation.strftime('%Y-%m-%d_%H-%M-%S')

            if name in names:
                names[name] += 1
                name = '{}_{}'.format(name, names[name] - 1)
            else:
                names[name] = 1

            new_fn = os.path.join(root, '{}{}'.format(name,ext))
            if fn != new_fn:
                os.rename(fn, new_fn)
                cnt += 1
    print '{} files renamed.'.format(cnt)

if __name__=='__main__':
    try:
        path = sys.argv[1]
    except IndexError:
        raise OSError('no path specified')
    datetime_renamer(path)

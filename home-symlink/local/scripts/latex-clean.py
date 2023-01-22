#!/usr/bin/env python3

import argparse
import os
import shutil
from time import time as now

BLACKLIST = set(
    [
        ".aux",
        ".bbl",
        ".fdb_latexmk",
        ".lot",
        ".lol",
        ".log",
        ".fls",
        ".bcf",
        ".toc",
        ".xml",
        ".lof",
        ".gz",
        ".blg",
        ".out",
    ]
)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument(
        "-d",
        "--destination",
        default=os.path.join(os.path.expanduser("~"), ".Trash"),
    )
    opts = ap.parse_args()

    if opts.path == ".":
        opts.path = os.getcwd()

    removed = 0

    for root, dirs, files in os.walk(opts.path):
        exts = set([os.path.splitext(f)[1] for f in files])
        if len(set.intersection(set([".tex"]), exts)) > 0:
            to_remove = [
                os.path.join(root, f)
                for f in files
                if os.path.splitext(f)[1] in BLACKLIST
            ]
            for f in to_remove:
                try:
                    shutil.move(f, opts.destination)
                except shutil.Error:
                    tr_name = (
                        "".join(f.split(".")[0])
                        + "-"
                        + "".join(list("%.0f" % (now() * 1e9))[9:])
                        + "."
                        + ".".join(f.split(".")[1:])
                    )
                    shutil.move(f, tr_name)
                    shutil.move(tr_name, opts.destination)
                removed += 1

    print("%s removed" % removed)


if __name__ == "__main__":
    main()

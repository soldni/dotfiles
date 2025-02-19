#! /usr/bin/env python3

"""
Script to execute the same scripts for all
files or folders in a directory in parallel.

Author: Luca Soldaini
Email:  luca@soldaini.net
"""

import argparse
import multiprocessing
import os

# import shlex
import subprocess


def type_is_dir_exists(fp):
    if os.path.isdir(fp):
        return fp
    err = '"{}" does not exists or is not a directory.'.format(fp)
    raise OSError(err)


def parse_options():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "-d",
        "--directory",
        required=True,
        type=type_is_dir_exists,
        help="Directory the script should be parallelized for",
    )
    ap.add_argument(
        "-s",
        "--script",
        required=True,
        help="The command or script to parallelize",
    )
    ap.add_argument(
        "-o",
        "--options",
        default="",
        help="Name of command line options the paths should be passsed to",
    )
    ap.add_argument(
        "-r",
        "--remaining",
        default="",
        help="Remaining arguments; will be shared across all parallel runs",
    )
    ap.add_argument(
        "-a",
        "--path-as-arg",
        default=False,
        action="store_true",
        help="If true, pass the path as argument",
    )
    ap.add_argument(
        "-c",
        "--cpu-count",
        type=int,
        default=(multiprocessing.cpu_count() - 1),
    )

    opts = ap.parse_args()
    return opts


def call(cmd):
    return subprocess.call(cmd, shell=True)


def driver():
    opts = parse_options()

    paths = [
        os.path.join(opts.directory, fn) for fn in os.listdir(opts.directory)
    ]

    process_args = [
        "{c}{a}{o} {r}".format(
            c=opts.script,
            a=" {} ".format(fp) if opts.path_as_arg else " ",
            o=" ".join(
                "{} {}".format(opt, fp) for opt in opts.options.strip().split()
            ),
            r=opts.remaining.strip(),
        )
        for fp in paths
    ]

    pool = multiprocessing.Pool(opts.cpu_count)
    pool.map(call, process_args)


if __name__ == "__main__":
    driver()

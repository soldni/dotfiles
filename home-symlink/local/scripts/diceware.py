#!/usr/bin/env python2

import random
from argparse import ArgumentParser
from math import ceil, log


def driver(opts):

    with file(opts.vocab) as wf:
        vocab = map(str.strip, wf.readlines())

    if opts.max_length > 0:
        vocab = [t for t in vocab if len(t) < opts.max_length]

    random_source = random.SystemRandom()

    words = []

    for i in xrange(opts.length):
        pos = random_source.randint(0, len(vocab))
        words.append(vocab[pos])

    words = map(lambda s: s.strip().lower(), words)
    return words


if __name__ == "__main__":
    ap = ArgumentParser("Generate passphrase using a vocabulary")
    ap.add_argument("length", type=int, help="length of passphrase in words")
    ap.add_argument(
        "-V",
        "--vocab",
        default="/usr/share/dict/words",
        help="vocabulary to use (plain text file, 1 word per line)",
    )
    ap.add_argument(
        "-s",
        "--separator",
        default="-",
        type=str,
        help="separator of words in passphrase",
    )
    ap.add_argument(
        "-M",
        "--max-length",
        default=0,
        type=int,
        help="Maximum length for any word",
    )
    opts = ap.parse_args()

    passphrase = driver(opts)
    out = opts.separator.join(passphrase)
    print(out)

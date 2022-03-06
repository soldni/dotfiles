#! /usr/bin/env bash

mode="${1}"
do_wheel="${2}"

rm -rf build/ dist/ *.egg-info/

if [ "${do_wheel}" == '-w' ] || [ "${mode}" == '-w' ]; then
    python setup.py sdist bdist_wheel
else
    python setup.py sdist
fi

if [ "${mode}" == 'release' ]; then
    python -m twine upload dist/*
elif [ "${mode}" == 'test' ]; then
    python -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*
else
    echo "DryRun"
fi

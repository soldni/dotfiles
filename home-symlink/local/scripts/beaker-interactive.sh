#!/usr/bin/env bash

if [ -z "${BEAKER_WORKSPACE}" ]; then
    BEAKER_WORKSPACE="ai2/lucas"
fi

if [ -z "${BEAKER_IMAGE}" ]; then
    BEAKER_IMAGE="beaker://lucas/pytorch_p310"
fi

if [ -z "${BEAKER_GPU_COUNT}" ]; then
    BEAKER_GPU_COUNT=0
fi

USAGE="Usage: $(basename $0) [-n BEAKER_HOST] {-g BEAKER_GPU_COUNT} {-i BEAKER_IMAGE} {-w BEAKER_WORKSPACE}"

while getopts 'n:g:i:w:h' OPTFLAG; do
  case "${OPTFLAG}" in
    n)
      BEAKER_HOST="${OPTARG}"
      ;;

    g)
      BEAKER_GPU_COUNT="${OPTARG}"
      ;;

    i)
      BEAKER_IMAGE="${OPTARG}"
      ;;

    i)
      BEAKER_WORKSPACE="${OPTARG}"
      ;;

    ?|h)
      echo ${USAGE} > /dev/stderr
      exit 1
      ;;
  esac
done

if [ -z "${BEAKER_HOST}" ]; then
    printf "Must provide host via -n!\n${USAGE}\n" > /dev/stderr
    exit 1
fi

# echo "BEAKER_HOST: ${BEAKER_HOST}"
# echo "BEAKER_GPU_COUNT: ${BEAKER_GPU_COUNT}"
# echo "BEAKER_IMAGE: ${BEAKER_IMAGE}"
# echo "BEAKER_WORKSPACE: ${BEAKER_WORKSPACE}"

ssh ${BEAKER_HOST} -t "beaker session create --gpus ${BEAKER_GPU_COUNT} --workspace ${BEAKER_WORKSPACE} --secret-mount aws-cred=~/.aws/credentials --image ${BEAKER_IMAGE}"

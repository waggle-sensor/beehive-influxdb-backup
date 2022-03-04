#!/bin/bash -eu

echo "running with config"
echo "UPLOAD_ADDR=${UPLOAD_ADDR}"
echo "UPLOAD_USER=${UPLOAD_USER}"
echo "UPLOAD_KEY=${UPLOAD_KEY}"
echo "UPLOAD_DIR=${UPLOAD_DIR}"

# get first pod for beehive-influxdb deployment
pod=$(kubectl get pod -l app=beehive-influxdb | awk '/beehive-influxdb/ {print $1; exit}')

if test -z "${pod}"; then
    echo "influxdb pod not found"
    exit 1
fi

echo "cleaning up existing backup files"
kubectl exec -i "${pod}" -- bash -c 'rm -rf /backup/*'

echo "exporting backup from influxdb"
kubectl exec -i "${pod}" -- influx backup -b waggle /backup

echo "moving files from ${pod}:/backup/ to /backup"
kubectl cp "${pod}:/backup/" "/backup/"
kubectl exec -i "${pod}" -- bash -c 'rm -rf /backup/*'

timestamp_for_backup() {
    path=$(find "${1}" -name '*.manifest')
    echo $(basename "${path}" | sed s/.manifest//)
}

timestamp=$(timestamp_for_backup /backup)

echo "rsyncing files to remote"
rsync \
    --verbose \
    --archive \
    --remove-source-files \
    -e "ssh -i ${UPLOAD_KEY} -o StrictHostKeyChecking=no" \
    /backup/ \
    "${UPLOAD_USER}@${UPLOAD_ADDR}:${UPLOAD_DIR}/${timestamp}/"

echo "done"

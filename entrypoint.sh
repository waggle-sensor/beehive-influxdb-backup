#!/bin/bash -e -u

echo "running with config"
echo "UPLOAD_ADDR=${UPLOAD_ADDR}"
echo "UPLOAD_USER=${UPLOAD_USER}"
echo "UPLOAD_KEY=${UPLOAD_KEY}"
echo "UPLOAD_DIR=${UPLOAD_DIR}"

pod=$(kubectl -n shared get pod | awk '/beehive-influxdb/ {print $1}')

if test -z "${pod}"; then
    echo "influxdb pod not found"
    exit 1
fi

echo "exporting backup from influxdb"
kubectl exec -it "${pod}" -- influx backup -b waggle /backup

echo "moving files from ${pod}:/backup/ to /backup"
kubectl cp "${pod}:/backup/" "$PWD/beehive-influxdb-backup"
kubectl exec -it "${pod}" -- bash -c "rm /backup/*"

echo "rsyncing files to remote"
rsync \
    --verbose \
    --archive \
    --remove-source-files \
    -e "ssh -i ${UPLOAD_KEY} -o StrictHostKeyChecking=no" \
    /backup/ \
    "${UPLOAD_USER}@${UPLOAD_ADDR}:${UPLOAD_DIR}/"

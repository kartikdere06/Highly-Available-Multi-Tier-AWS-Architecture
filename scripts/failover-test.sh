#!/usr/bin/env bash
# Forces an RDS Multi-AZ failover and measures how long the instance takes to
# report "available" again, while polling the app URL for HTTP errors.
#
# Usage: ./scripts/failover-test.sh <db-instance-id> <url>
# Requires: aws CLI v2 with credentials, curl.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <db-instance-id> <url>" >&2
  exit 1
fi

DB_ID="$1"
URL="$2"

echo "Current state:"
aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].[DBInstanceStatus,AvailabilityZone,SecondaryAvailabilityZone,MultiAZ]' \
  --output text

START=$(date +%s)
echo "Triggering failover at $(date +%T)..."
aws rds reboot-db-instance --db-instance-identifier "$DB_ID" --force-failover >/dev/null

# Wait until the reboot has actually begun (status leaves 'available').
while [ "$(aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].DBInstanceStatus' --output text)" = "available" ]; do
  sleep 2
done
echo "Status left 'available' after $(( $(date +%s) - START ))s"

HTTP_FAILS=0
while true; do
  STATUS=$(aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
    --query 'DBInstances[0].DBInstanceStatus' --output text)

  CODE=$(curl -s -o /dev/null -m 5 -w "%{http_code}" "$URL" || true)
  if [ "$CODE" != "200" ]; then
    HTTP_FAILS=$((HTTP_FAILS + 1))
  fi

  echo "$(date +%T)  db=$STATUS  http=$CODE"

  if [ "$STATUS" = "available" ]; then
    break
  fi
  sleep 5
done

END=$(date +%s)
echo
echo "DB returned to 'available' after $((END - START))s"
echo "Non-200 responses from $URL during the test: $HTTP_FAILS"
echo
echo "Recent RDS events:"
aws rds describe-events --source-type db-instance --source-identifier "$DB_ID" \
  --duration 30 --query 'Events[].[Date,Message]' --output text
echo
echo "New AZ layout:"
aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].[AvailabilityZone,SecondaryAvailabilityZone]' --output text

# Failover Test Log

Run each test against your own deployment and record what you actually measure. Leave a cell blank if you did not run the test. Do not publish numbers you did not measure.

Environment: region `________`, date `________`, instance type `________`, DB class `________`

## Test 1: Instance failure

1. Open the app URL and note the instance ID shown.
2. In a second terminal, poll the URL once per second:
   ```bash
   while true; do date +%T; curl -s -o /dev/null -w "%{http_code}\n" "$URL"; sleep 1; done
   ```
3. Terminate that instance:
   ```bash
   aws ec2 terminate-instances --instance-ids <instance-id>
   ```
4. Record whether any requests failed, and how long until the ASG launched a replacement and it became healthy.

| Metric | Result |
|--------|--------|
| Failed requests during the test | |
| Time until a replacement instance was InService | |

## Test 2: Availability Zone loss (simulated)

1. List instances per AZ: `aws ec2 describe-instances --filters Name=tag:Name,Values=ha-three-tier-app --query 'Reservations[].Instances[].[InstanceId,Placement.AvailabilityZone]'`
2. Terminate all instances in one AZ.
3. Keep polling the URL and record the behaviour.

| Metric | Result |
|--------|--------|
| Did the site stay reachable via the other AZ? | |
| Time until capacity was restored in both AZs | |

## Test 3: RDS Multi-AZ failover

Use the helper script, which reboots the DB with forced failover and reports how long the endpoint takes to accept connections again:

```bash
./scripts/failover-test.sh <db_instance_id> <app-url>
```

Or manually:

```bash
aws rds reboot-db-instance --db-instance-identifier <db_instance_id> --force-failover
aws rds describe-events --source-type db-instance --source-identifier <db_instance_id> --duration 30
```

| Metric | Result |
|--------|--------|
| Time from reboot request to "Multi-AZ failover completed" event | |
| Time until DB status returned to `available` | |

## Notes

Anything unexpected, and what you changed as a result.

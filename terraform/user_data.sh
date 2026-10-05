#!/bin/bash
# Bootstraps a tiny web server that reports which instance and AZ served the request.
# Useful for demonstrating load balancing and for failover tests.
set -euxo pipefail

dnf install -y httpd
systemctl enable --now httpd

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

echo "ok" > /var/www/html/health

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head><title>HA Three-Tier Demo</title></head>
  <body style="font-family: sans-serif; max-width: 40rem; margin: 3rem auto;">
    <h1>Highly Available 3-Tier Architecture</h1>
    <p>Served by instance <strong>${INSTANCE_ID}</strong> in <strong>${AZ}</strong>.</p>
    <p>Refresh to see requests move between instances and Availability Zones.</p>
  </body>
</html>
EOF

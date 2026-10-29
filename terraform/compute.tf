
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix            = "${var.project_name}-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    dnf install -y nodejs npm
    mkdir -p /opt/assessment
    cd /opt/assessment
    npm init -y
    npm install mysql2 @aws-sdk/client-secrets-manager

    cat > /opt/assessment/server.js <<'APP'
    const http = require('http');
    const os = require('os');
    const mysql = require('mysql2/promise');
    const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

    const port = 8080;
    const secretArn = '${aws_secretsmanager_secret.db.arn}';
    const region = '${var.aws_region}';
    const secretsClient = new SecretsManagerClient({ region });

    let cachedSecret;
    let cachedSecretTime = 0;

    async function getDbSecret() {
      if (cachedSecret && Date.now() - cachedSecretTime < 300000) {
        return cachedSecret;
      }

      const result = await secretsClient.send(
        new GetSecretValueCommand({ SecretId: secretArn })
      );

      if (!result.SecretString) {
        throw new Error('Database secret has no SecretString');
      }

      cachedSecret = JSON.parse(result.SecretString);
      cachedSecretTime = Date.now();
      return cachedSecret;
    }

    async function checkDatabase() {
      const secret = await getDbSecret();
      const connection = await mysql.createConnection({
        host: secret.host,
        port: Number(secret.port || 3306),
        user: secret.username,
        password: secret.password,
        database: secret.dbname,
        connectTimeout: 5000,
      });

      try {
        const [rows] = await connection.query('SELECT 1 AS ok');
        return rows[0].ok === 1;
      } finally {
        await connection.end();
      }
    }

    const page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AWS DevOps Assessment</title></head><body style="font:18px system-ui;max-width:760px;margin:10vh auto;padding:24px"><h1>AWS Terraform DevOps Assessment</h1><p>Served by a private EC2 instance behind an Application Load Balancer.</p><p>Instance: ' + os.hostname() + '</p><p>Database status: <a href="/db-health">Check connection</a></p><p>Infrastructure: Terraform, Auto Scaling, ALB, private EC2 and RDS MySQL.</p></body></html>';

    http.createServer(async (req, res) => {
      if (req.url === '/health') {
        res.writeHead(200, { 'content-type': 'application/json' });
        return res.end(JSON.stringify({ status: 'healthy', host: os.hostname() }));
      }

      if (req.url === '/db-health') {
        try {
          const connected = await checkDatabase();
          res.writeHead(connected ? 200 : 503, { 'content-type': 'application/json' });
          return res.end(JSON.stringify({ status: connected ? 'connected' : 'failed' }));
        } catch (err) {
          console.error('Database health check failed:', err.message);
          res.writeHead(503, { 'content-type': 'application/json' });
          return res.end(JSON.stringify({ status: 'unavailable' }));
        }
      }

      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      res.end(page);
    }).listen(port, '0.0.0.0', () => console.log('Listening on ' + port));
    APP

    cat > /etc/systemd/system/assessment-app.service <<'SERVICE'
    [Unit]
    Description=AWS assessment web application
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    WorkingDirectory=/opt/assessment
    ExecStart=/usr/bin/node /opt/assessment/server.js
    Restart=always
    RestartSec=5
    User=root

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now assessment-app
  USERDATA
  )

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.project_name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = aws_subnet.app[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}

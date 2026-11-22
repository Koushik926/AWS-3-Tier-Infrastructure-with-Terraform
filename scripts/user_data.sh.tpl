#!/bin/bash
# =============================================================================
# User Data Script - AWS 3-Tier Application Bootstrap
# =============================================================================
# This script installs and configures:
# - Nginx (reverse proxy)
# - Python Flask application (served with gunicorn)
# - CloudWatch Agent
# - MySQL client
# =============================================================================

set -euo pipefail

# Variables from Terraform
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_NAME="${db_name}"
DB_SECRET_ARN="${db_secret_arn}"
AWS_REGION="${aws_region}"
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"

# Logging setup
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=========================================="
echo "Starting user data script at $(date)"
echo "=========================================="

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# -----------------------------------------------------------------------------
# System Updates and Package Installation
# -----------------------------------------------------------------------------
log "Updating system packages..."
dnf update -y || error_exit "Failed to update packages"

log "Installing required packages..."
dnf install -y \
    nginx \
    python3 \
    python3-pip \
    mariadb105 \
    amazon-cloudwatch-agent \
    jq \
    stress-ng \
    || error_exit "Failed to install packages"

# -----------------------------------------------------------------------------
# Python Virtual Environment and Dependencies
# -----------------------------------------------------------------------------
log "Setting up Python virtual environment..."
python3 -m venv /opt/app/venv
source /opt/app/venv/bin/activate

log "Installing Python dependencies..."
pip install --upgrade pip
pip install flask gunicorn boto3 pymysql || error_exit "Failed to install Python packages"

# -----------------------------------------------------------------------------
# Flask Application
# -----------------------------------------------------------------------------
log "Creating Flask application..."
mkdir -p /opt/app

cat > /opt/app/app.py << 'FLASK_APP'
#!/usr/bin/env python3
"""
AWS 3-Tier Architecture Demo Application
Demonstrates connectivity between web tier, app tier, and database tier.
"""

import json
import os
import urllib.request
from datetime import datetime
from flask import Flask, jsonify, render_template_string

import boto3
import pymysql

app = Flask(__name__)

# Configuration from environment
DB_HOST = os.environ.get('DB_HOST')
DB_PORT = int(os.environ.get('DB_PORT', 3306))
DB_NAME = os.environ.get('DB_NAME')
DB_SECRET_ARN = os.environ.get('DB_SECRET_ARN')
AWS_REGION = os.environ.get('AWS_REGION', 'ap-south-1')
PROJECT_NAME = os.environ.get('PROJECT_NAME', 'AWS 3-Tier App')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')


def get_imds_token():
    """Get IMDSv2 token for metadata requests."""
    req = urllib.request.Request(
        'http://169.254.169.254/latest/api/token',
        method='PUT',
        headers={'X-aws-ec2-metadata-token-ttl-seconds': '300'}
    )
    with urllib.request.urlopen(req, timeout=2) as response:
        return response.read().decode('utf-8')


def get_instance_metadata():
    """Retrieve instance metadata using IMDSv2."""
    try:
        token = get_imds_token()
        headers = {'X-aws-ec2-metadata-token': token}

        def fetch(path):
            req = urllib.request.Request(
                f'http://169.254.169.254/latest/meta-data/{path}',
                headers=headers
            )
            with urllib.request.urlopen(req, timeout=2) as response:
                return response.read().decode('utf-8')

        return {
            'instance_id': fetch('instance-id'),
            'availability_zone': fetch('placement/availability-zone'),
            'private_ip': fetch('local-ipv4'),
        }
    except Exception as e:
        return {
            'instance_id': 'unknown',
            'availability_zone': 'unknown',
            'private_ip': 'unknown',
            'error': str(e)
        }


def get_db_credentials():
    """Retrieve database credentials from Secrets Manager."""
    try:
        client = boto3.client('secretsmanager', region_name=AWS_REGION)
        response = client.get_secret_value(SecretId=DB_SECRET_ARN)
        return json.loads(response['SecretString'])
    except Exception as e:
        app.logger.error(f"Failed to get DB credentials: {e}")
        return None


def get_db_connection():
    """Create a database connection using credentials from Secrets Manager."""
    creds = get_db_credentials()
    if not creds:
        return None

    try:
        connection = pymysql.connect(
            host=creds['host'],
            port=int(creds['port']),
            user=creds['username'],
            password=creds['password'],
            database=creds['dbname'],
            connect_timeout=5,
            cursorclass=pymysql.cursors.DictCursor
        )
        return connection
    except Exception as e:
        app.logger.error(f"Database connection failed: {e}")
        return None


def check_db_connection():
    """Check database connectivity and return status."""
    try:
        conn = get_db_connection()
        if conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT VERSION() as version")
                result = cursor.fetchone()
            conn.close()
            return {'status': 'connected', 'version': result['version']}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}
    return {'status': 'failed', 'error': 'Could not establish connection'}


# HTML Template for the main page
HOME_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ project_name }} | {{ environment }}</title>
    <style>
        :root {
            --bg: #0f172a;
            --card-bg: #1e293b;
            --text: #f1f5f9;
            --text-muted: #94a3b8;
            --accent: #3b82f6;
            --success: #22c55e;
            --error: #ef4444;
            --border: #334155;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 700px;
            width: 100%;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            font-size: 2rem;
            margin-bottom: 8px;
            background: linear-gradient(135deg, var(--accent), #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .header .env-badge {
            display: inline-block;
            background: var(--accent);
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .card {
            background: var(--card-bg);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 20px;
        }
        .card h2 {
            font-size: 1rem;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid var(--border);
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }
        .info-item {
            padding: 12px;
            background: rgba(0,0,0,0.2);
            border-radius: 8px;
        }
        .info-item label {
            display: block;
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-bottom: 4px;
            text-transform: uppercase;
        }
        .info-item .value {
            font-family: 'Consolas', monospace;
            font-size: 0.95rem;
            word-break: break-all;
        }
        .status {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .status-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        .status-dot.connected { background: var(--success); }
        .status-dot.failed { background: var(--error); }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .endpoints {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }
        .endpoint {
            background: var(--accent);
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 0.9rem;
            transition: transform 0.2s, opacity 0.2s;
        }
        .endpoint:hover {
            transform: translateY(-2px);
            opacity: 0.9;
        }
        .footer {
            text-align: center;
            color: var(--text-muted);
            font-size: 0.8rem;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{ project_name }}</h1>
            <span class="env-badge">{{ environment }}</span>
        </div>

        <div class="card">
            <h2>Instance Information</h2>
            <div class="info-grid">
                <div class="info-item">
                    <label>Instance ID</label>
                    <div class="value">{{ instance_id }}</div>
                </div>
                <div class="info-item">
                    <label>Availability Zone</label>
                    <div class="value">{{ availability_zone }}</div>
                </div>
                <div class="info-item">
                    <label>Private IP</label>
                    <div class="value">{{ private_ip }}</div>
                </div>
                <div class="info-item">
                    <label>Timestamp</label>
                    <div class="value">{{ timestamp }}</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>Database Status</h2>
            <div class="info-grid">
                <div class="info-item">
                    <label>Connection</label>
                    <div class="status">
                        <span class="status-dot {{ db_status }}"></span>
                        <span class="value">{{ db_status | title }}</span>
                    </div>
                </div>
                <div class="info-item">
                    <label>MySQL Version</label>
                    <div class="value">{{ db_version }}</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>API Endpoints</h2>
            <div class="endpoints">
                <a href="/health" class="endpoint">Health Check</a>
                <a href="/db" class="endpoint">Database Test</a>
            </div>
        </div>

        <div class="footer">
            AWS 3-Tier Infrastructure with Terraform | Portfolio Project by R Koushik
        </div>
    </div>
</body>
</html>
"""


@app.route('/')
def home():
    """Main page showing instance info and DB status."""
    metadata = get_instance_metadata()
    db_check = check_db_connection()

    return render_template_string(
        HOME_TEMPLATE,
        project_name=PROJECT_NAME,
        environment=ENVIRONMENT.upper(),
        instance_id=metadata.get('instance_id', 'unknown'),
        availability_zone=metadata.get('availability_zone', 'unknown'),
        private_ip=metadata.get('private_ip', 'unknown'),
        timestamp=datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'),
        db_status=db_check.get('status', 'unknown'),
        db_version=db_check.get('version', db_check.get('error', 'N/A'))
    )


@app.route('/health')
def health():
    """
    Health check endpoint for ALB.
    Returns 200 OK without checking the database to ensure
    instances stay healthy even if DB is temporarily unavailable.
    """
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.utcnow().isoformat(),
        'instance': get_instance_metadata().get('instance_id', 'unknown')
    }), 200


@app.route('/db')
def db_test():
    """
    Database connectivity test endpoint.
    Creates a visits table, inserts a row, and returns the total count.
    """
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({
                'status': 'error',
                'message': 'Could not connect to database'
            }), 500

        metadata = get_instance_metadata()

        with conn.cursor() as cursor:
            # Create visits table if not exists
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS visits (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    instance_id VARCHAR(50),
                    availability_zone VARCHAR(20),
                    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            # Insert a visit record
            cursor.execute(
                "INSERT INTO visits (instance_id, availability_zone) VALUES (%s, %s)",
                (metadata['instance_id'], metadata['availability_zone'])
            )
            conn.commit()

            # Get total visit count
            cursor.execute("SELECT COUNT(*) as count FROM visits")
            result = cursor.fetchone()

            # Get recent visits
            cursor.execute("""
                SELECT instance_id, availability_zone, visit_time
                FROM visits
                ORDER BY visit_time DESC
                LIMIT 5
            """)
            recent = cursor.fetchall()

        conn.close()

        return jsonify({
            'status': 'success',
            'message': 'Database connection successful',
            'total_visits': result['count'],
            'current_instance': metadata['instance_id'],
            'availability_zone': metadata['availability_zone'],
            'recent_visits': [
                {
                    'instance': v['instance_id'],
                    'az': v['availability_zone'],
                    'time': v['visit_time'].isoformat()
                } for v in recent
            ]
        }), 200

    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
FLASK_APP

# -----------------------------------------------------------------------------
# Systemd Service for Gunicorn
# -----------------------------------------------------------------------------
log "Creating systemd service for the application..."

cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=AWS 3-Tier Demo Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment="PATH=/opt/app/venv/bin"
Environment="DB_HOST=$DB_HOST"
Environment="DB_PORT=$DB_PORT"
Environment="DB_NAME=$DB_NAME"
Environment="DB_SECRET_ARN=$DB_SECRET_ARN"
Environment="AWS_REGION=$AWS_REGION"
Environment="PROJECT_NAME=$PROJECT_NAME"
Environment="ENVIRONMENT=$ENVIRONMENT"
ExecStart=/opt/app/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:8000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------------------------------------------------------
# Nginx Configuration
# -----------------------------------------------------------------------------
log "Configuring Nginx as reverse proxy..."

cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_read_timeout 30s;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Remove default nginx config
rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

# Test nginx configuration
nginx -t || error_exit "Nginx configuration test failed"

# -----------------------------------------------------------------------------
# CloudWatch Agent Configuration
# -----------------------------------------------------------------------------
log "Configuring CloudWatch Agent..."

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "namespace": "$PROJECT_NAME/$ENVIRONMENT",
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent", "mem_available_percent"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["disk_used_percent"],
                "resources": ["/"],
                "metrics_collection_interval": 60
            }
        },
        "append_dimensions": {
            "InstanceId": "\$${aws:InstanceId}",
            "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}"
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/$PROJECT_NAME/$ENVIRONMENT/nginx/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/$PROJECT_NAME/$ENVIRONMENT/nginx/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/$PROJECT_NAME/$ENVIRONMENT/user-data",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    }
}
EOF

# -----------------------------------------------------------------------------
# Start Services
# -----------------------------------------------------------------------------
log "Starting services..."

# Reload systemd
systemctl daemon-reload

# Start and enable services
systemctl start app
systemctl enable app

systemctl start nginx
systemctl enable nginx

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# -----------------------------------------------------------------------------
# Verify Services
# -----------------------------------------------------------------------------
log "Verifying services..."

sleep 5

# Check if app is running
if systemctl is-active --quiet app; then
    log "Application service is running"
else
    error_exit "Application service failed to start"
fi

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    log "Nginx service is running"
else
    error_exit "Nginx service failed to start"
fi

# Test health endpoint
if curl -sf http://localhost/health > /dev/null; then
    log "Health endpoint responding"
else
    log "WARNING: Health endpoint not responding yet (may need more time)"
fi

log "=========================================="
log "User data script completed successfully!"
log "=========================================="

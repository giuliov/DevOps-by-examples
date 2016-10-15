#!/bin/bash

cd $HOME

## setup nginx
cat <<'EOF' > nginx-default
server {
    listen 80;
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

sudo cp --force nginx-default /etc/nginx/sites-available/default
rm nginx-default
sudo nginx -s reload

## run app as a daemon
cat <<'EOF' > devops-by-examples-app.conf
[program:devops-by-examples-app]
command=/usr/bin/dotnet /opt/devops-by-examples/app/app.dll
directory=/opt/devops-by-examples/app/
autostart=true
autorestart=true
stderr_logfile=/var/log/devops-by-examples.err.log
stdout_logfile=/var/log/devops-by-examples.out.log
environment=HOME=/var/www/,ASPNETCORE_ENVIRONMENT=Production
user=www-data
stopsignal=INT
stopasgroup=true
killasgroup=true
EOF

sudo cp --force devops-by-examples-app.conf /etc/supervisor/conf.d/
sudo service supervisor stop
sudo service supervisor start

#!/bin/bash
apt update
apt -y install curl gnupg2 ca-certificates lsb-release ubuntu-keyring
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
  | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
  | sudo tee /etc/apt/preferences.d/99nginx
apt update
apt install -y nginx

echo "<h1>Hello, World!!</h1>" > /usr/share/nginx/html/index.html

sudo sed -i '/location \/ {/,/}/c\
location / {\
  # root   /usr/share/nginx/html;\
  # index  index.html index.htm;\
\
  proxy_pass http://${fastapi_private_ip}:8000;\
  proxy_set_header Host $host;\
  proxy_set_header X-Real-IP $remote_addr;\
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
  proxy_set_header X-Forwarded-Proto $scheme;\
\
  gzip on;\
  gzip_types text/plain application/xml application/json text/css text/javascript application/javascript;\
  gzip_min_length 1000;\
}\
' /etc/nginx/conf.d/default.conf

systemctl start nginx
systemctl enable nginx
set -x

if [[ -n $APT ]]; then
  decode_TEMPLATE.preconf-debian.sh preconf.sh
  decode_TEMPLATE.install-nginx-debian.sh install-nginx.sh
elif [[ -n $YUM ]]; then
  decode_TEMPLATE.preconf-centos.sh preconf.sh
  decode_TEMPLATE.install-nginx-centos.sh install-nginx.sh
else
  echo "Unknown Linux"
  exit;
fi

chmod +x preconf.sh
./preconf.sh

chmod +x install-nginx.sh
./install-nginx.sh
decode_TEMPLATE.nginx.conf /etc/nginx/nginx.conf
decode_TEMPLATE.virtualhost.conf /etc/nginx/conf.d/$VIRTUALHOST.conf
decode_TEMPLATE.default.conf /etc/nginx/conf.d/default.conf
decode_TEMPLATE.fullchain.pem /etc/nginx/ssl/$VIRTUALHOST.crt
decode_TEMPLATE.privkey.pem /etc/nginx/ssl/$VIRTUALHOST.key


sed -i -e "s/WEB_BACKEND1_IP/$WEB_BACKEND1_IP/g" /etc/nginx/conf.d/*.conf
sed -i -e "s/WEB_BACKEND2_IP/$WEB_BACKEND2_IP/g" /etc/nginx/conf.d/*.conf
sed -i -e "s/REALIP/$REALIP/g" /etc/nginx/conf.d/*.conf
sed -i -e "s/VIRTUALHOST/$VIRTUALHOST/g" /etc/nginx/conf.d/*.conf

[[ -n $YUM ]] && sed -i -e "s/www-data/nginx/g" /etc/nginx/nginx.conf
service nginx restart



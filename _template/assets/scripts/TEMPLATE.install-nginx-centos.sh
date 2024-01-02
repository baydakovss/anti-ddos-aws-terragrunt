# install nginx
yum install -y nginx
chkconfig nginx on

mkdir -p /var/cache/nginx/proxy
mkdir /etc/nginx/ssl
cp -ar /etc/nginx /etc/nginx~orig



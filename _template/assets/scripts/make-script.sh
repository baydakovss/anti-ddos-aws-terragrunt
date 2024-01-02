#!/bin/bash
source ./TEMPLATE.vars
source ../config.env

echo $VIRTUALHOST

MAIN_TEMPLATE="TEMPLATE.INSTALL.sh  "
EXTRA_TEMPLATES="\
TEMPLATE.install-nginx-centos.sh \
TEMPLATE.preconf-centos.sh \
TEMPLATE.virtualhost.conf \
TEMPLATE.default.conf \
../certs/TEMPLATE.fullchain.pem \
../certs/TEMPLATE.privkey.pem \
"
SCRIPT_NAME="../user-data/INSTALL.sh"

cat <<HEADER >$SCRIPT_NAME
#!/bin/bash

HEADER

for i in $EXTRA_TEMPLATES ; do
    TEMPLATE=`basename $i`
    cat <<EOF >>$SCRIPT_NAME
function decode_$TEMPLATE () {

    local FILENAME=\$1
    cat <<$TEMPLATE | base64 -d | gzip -d -c >\$FILENAME
EOF

base64 <(gzip -c $i) >>$SCRIPT_NAME
#base64 <$TEMPLATE >>$SCRIPT_NAME

    cat <<EOF >>$SCRIPT_NAME
$TEMPLATE

}

EOF

done

cat TEMPLATE.vars >>$SCRIPT_NAME

cat ../config.env | sed 's/VIRTUALHOST=$(basename "$(dirname "$(pwd)")")/VIRTUALHOST='"$(basename "$(dirname "$(pwd)")")"'/g'  >>$SCRIPT_NAME

cat $MAIN_TEMPLATE >>$SCRIPT_NAME


cat <<FOOTER >>$SCRIPT_NAME

FOOTER

chmod +x $SCRIPT_NAME

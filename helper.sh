#!/bin/bash

if test -f ./config.env; then
  source ./config.env
fi

param_action=""
depth_folder=2

usage () {
cat <<END_OF_USAGE
helper.sh
Usage: $0 [args]
  -a,  --action ACTION      - set ACTION to make_skeleton, fetch_certs, generate_userdata
  -h,  --help               - print this message
END_OF_USAGE
}

make_skeleton () {
  local profile
  local domain
  local region

  echo "Specify aws profile name:"
  read profile

  echo "Specify aws region:"
  read region

  echo "Specify domain name:"
  read domain


  mkdir -p infrastructure/live/${domain}/profiles/${profile}/${region}
  cp _template/terragrunt.hcl infrastructure/live/${domain}/profiles/${profile}/${region}/
  cp _template/common.hcl infrastructure/live/${domain}/

  mkdir -p infrastructure/live/global/profiles/${profile}
  cp _template/global.hcl infrastructure/live/global/profiles/${profile}/terragrunt.hcl

  mkdir -p assets/${domain}/{certs,user-data}
  cp -ra _template/assets/* assets/${domain}
}

fetch_certs () {
    echo "****  Please consider modifying the process of obtaining certificates  ****"
    echo "****  Feel free to put {cert,privkey,chain,fullhcain}.pem on your own with names {TEMPLATE.cert,TEMPLATE.privkey,TEMPLATE.chain,TEMPLATE.fullhcain}.pem  for each domain in 'assets/DOMAIN/certs' folder ****"
    echo "Fetch certs"
    pushd $(pwd) > /dev/null
    cd ./assets
    for i in $(find . -mindepth $depth_folder -maxdepth $depth_folder -type d -name certs ); do

      VIRTUALHOST=$(basename "$(dirname $i)")
      echo "Fetch certificates for $VIRTUALHOST:"

        scp -P 34107 $user@$host:/opt/ssl/letsencrypt/$VIRTUALHOST/cert.pem $i/TEMPLATE.cert.pem
        scp -P 34107 $user@$host:/opt/ssl/letsencrypt/$VIRTUALHOST/privkey.pem $i/TEMPLATE.privkey.pem
        scp -P 34107 $user@$host:/opt/ssl/letsencrypt/$VIRTUALHOST/chain.pem $i/TEMPLATE.chain.pem
        scp -P 34107 $user@$host:/opt/ssl/letsencrypt/$VIRTUALHOST/fullchain.pem $i/TEMPLATE.fullchain.pem
    done
    popd >/dev/null

    return $?
}

generate_userdata () {
    pushd $(pwd) > /dev/null

    for i in $(find ./assets -mindepth $depth_folder -maxdepth $depth_folder -type d -name scripts | grep -v "_"); do
      VIRTUALHOST=$(basename "$(dirname $i)")
      PROJECT_FOLDER=$(dirname $i)
      echo "Generate userdata for $VIRTUALHOST..."

      if [ -z "$(ls -A $PROJECT_FOLDER/certs)" ]; then
        echo "****  Folder $PROJECT_FOLDER/certs is empty. Please copy certificates into with names {TEMPLATE.cert,TEMPLATE.privkey,TEMPLATE.chain,TEMPLATE.fullhcain}.pem. Skiped for now  ****"
        exit 1
      fi

      if ! test -f ../config.env; then
        echo "****  Please copy file $(dirname $i)/config.env-orig to $(dirname $i)/config.env and change upstreams. Skiped for now  ****"
        exit 1
      fi

      cd $i
      ./make-script.sh
    done

    popd >/dev/null
    return $?
}


# arguments parsing
while [ $# -gt 0 ]; do
    case $1 in
        -a|--action)
            param_action="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unrecognized option '$1'. Aborting!"
            exit 1
            ;;
    esac
done

if [ -n "$param_action" ]; then
    action=$param_action
fi

# check existing required arguments
if [ -z "$action" ]; then
    echo "Missing required argument 'action'"
fi


case "$action" in
    make_skeleton)
        make_skeleton
        exit $?
    ;;
    generate_userdata)
        generate_userdata
        exit $?
    ;;
    fetch_certs)
        fetch_certs
        exit $?
    ;;
    *)
        echo "Error: Bad action '$action'. Aborted!"
        exit 1
    ;;

esac


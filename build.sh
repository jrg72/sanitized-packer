#!/bin/bash

## builds images with packer.

set -e -u -o pipefail

function join {
    local IFS="$1"
    shift
    echo "$*"
}

basedir=$( cd "$( dirname "${0}" )" && /bin/pwd )
workdir="${basedir}/work"
fifo="${workdir}/fifo"

## packer works relative to the path of the passed-in json file; this is just
## simpler
cd "${basedir}"

function cleanup {
    EXIT=$?
    if [ -e "${fifo}" ]; then
        rm -f "${fifo}"
    fi
    
    ## if we're root, make sure the artifacts we generated can be removed by the
    ## owner of the directory.
    if [ "${EUID}" -eq 0 ]; then
        chown -R "$( stat --format='%u:%g' "${basedir}" )" "${workdir}"
    fi

    exit ${EXIT}
}
trap cleanup EXIT

if [ ! -d "${workdir}" ]; then
    mkdir "${workdir}"
fi

if [ $# -eq 0 ]; then
    echo "usage: $0 <packer_yaml> [packer_arg1 ... packer_argN]"
    echo
    echo "with no arguments, builds all AMIs"
    echo
    echo "building a single AMI:"
    echo "    $0 <packer_yaml> -var source_ami=ami-XXXXXX -only=ami-whatever"
    echo
    echo "building a Vagrant sandbox:"
    echo "    $0 <packer_yaml> -var source_ami=vbox_yo -only=vbox-container-host-mlkernel"
    exit 1
fi

packer_yaml="${1}"
packer_json="${packer_yaml%.*}.json"
shift 1


packer_args=( $@ )

if [ ! -e "${packer_yaml}" ]; then
    echo "${packer_yaml} does not exist!"
    exit 1
fi

"${basedir}"/yaml2json.py "${packer_yaml}" >| "${packer_json}"

## provide git_sha if not specified
if [[ ! "${packer_args[*]:-}" =~ -var\ git_sha= ]]; then
    packer_args+=( "-var" "git_sha=$( git describe --always --dirty )" )
fi

## check to see if user passed a list of builders with -only=builder1,builderN
builders=()
for arg in "${packer_args[@]}"; do
    if [[ $arg == -only=* ]]; then
        builders=( "$( echo "${arg#-only=}" | tr , ' ' )" )
        break
    fi
done

if [ ${#builders[@]} -eq 0 ]; then
    ## nope.  so build all AMIs.
    read -r -a builders < <( 
        packer inspect -machine-readable "${packer_json}" | \
        awk -F, '/,template-builder,ami-/ { printf("%s ", $4) } END{ print "" }'
    )

    packer_args+=( "-only=$( join , "${builders[@]}" )" )
fi

## ensure the skel tarballs exist for each builder.  we actually do the
## packaging in the packer config, but validation needs to see that the files
## exist.
for builder in "${builders[@]}"; do
    jq -r '.provisioners[] | select(.destination == "/tmp/packer-skel.tgz") | .source' "${packer_json}" | while read -r tarball; do
        touch "$( echo "${tarball}" | sed -e "s#{{ template_dir }}#${PWD}#" -e "s#{{ build_name }}#${builder}#" )"
    done
done

## check to see if user passed a list of cookbooks with -var recipes="recipe[cookbook::recipe]"
cookbooks=()
for arg in "${packer_args[@]}"; do
    if [[ $arg == recipes=* ]]; then
        cookbooks=( "$( echo "${arg#recipes=}" | tr , ' ' )" )
        break
    fi
done

## quick-n-dirty validation
## validate doesn't take -debug
pv_args=( ${packer_args[@]} )
for i in "${!pv_args[@]}"; do 
    if [ "${pv_args[$i]}" = "-debug" ]; then
        unset "pv_args[$i]" 
    fi
done 
packer-io validate "${pv_args[@]}" "${packer_json}"

rm -rf "${basedir}/vendor/cookbooks/"
mkdir -p "${basedir}/vendor/cookbooks/"
#berks vendor "${basedir}/vendor/cookbooks/" --delete
for cookbook in "${cookbooks[@]}"; do
  for item in ${cookbook}; do
    item=`echo ${item} | sed s/::.*// | sed s/\"//g`
#    echo ${item}
    berks vendor --berksfile cookbooks/${item}/Berksfile "${basedir}/vendor/cookbooks/"
  done
done
berks vendor --berksfile cookbooks/chef-plm_base/Berksfile "${basedir}/vendor/cookbooks/"

#echo ${cookbook}

#exit

## ok, this rabbit hole's gettin' pretty deep.  if we just did
##   packer | extract_artifacts.py
## then the user typing ^C would interrupt the filter and not the packer
## process.
mkfifo "${fifo}"

"${basedir}/extract_artifacts.py" "${fifo}" &
packer-io build -force -machine-readable "${packer_args[@]}" "${packer_json}" > "${fifo}"

## wait for the filter to complete, which should be instantaneous…
wait

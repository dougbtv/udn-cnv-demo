#!/bin/bash
pushd ./bin
    if [ ! -f ./virtctl ]; then
        kubevirt_stable_release_url=$(get_kubevirt_release_url "stable")
        cli_name="virtctl-${kubevirt_stable_release_url##*/}-${OS_TYPE}-${ARCH}"
        curl -LO "${kubevirt_stable_release_url}/${cli_name}"
        mv ${cli_name} virtctl
        if_error_exit "Failed to download virtctl!"
    fi
popd

chmod +x ./bin/virtctl

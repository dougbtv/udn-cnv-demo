#!/bin/bash

./01-cluster-create.sh && ./02-cnv-setup.sh && ./03-storage-setup.sh && ./04-launch-vm.sh | tee all.log
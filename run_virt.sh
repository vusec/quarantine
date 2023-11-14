#!/bin/sh

virtme-run \
    --name quarantine \
    --kdir linux-5.15-quarantine-virt  \
    --cwd virt_home \
    --rwdir virt_home \
    --mods auto \
    --kopt "noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off" \
    --kopt "nospec_store_bypass_disable no_stf_barrier mds=off tsx=on" \
    --kopt "tsx_async_abort=off mitigations=off ignore_loglevel nokaslr nosmap nosmep" \
    --qemu-opts \
        -s \
        -smp cores=2,threads=2 \
        -m 8G \
        -device e1000,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::5556-:80 \
        -enable-kvm

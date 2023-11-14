#!/bin/sh

#virtme-prep-kdir-mods

virtme-run \
    `# virtme params` \
    --kdir ./linux-5.15-quarantine-kernel  \
    --name sysiso-qemu \
    --cwd './linux-5.15-quarantine-kernel/security/sysiso/userspace/' \
    --rwdir './linux-5.15-quarantine-kernel/security/sysiso/userspace/' \
    `# kernel params (looks like they must be before --qemu-opts)` \
    `# https://make-linux-fast-again.com/` \
    -a "noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off" \
    -a 'nokaslr' \
    -a 'nosmap' \
    -a 'nosmep' \
    -a 'ignore_loglevel' \
    `# qemu params` \
    --qemu-opts \
    -s \
    -smp cores=8,threads=2 \
    -m 2G \
    -device e1000,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::5556-:80 \
    -enable-kvm

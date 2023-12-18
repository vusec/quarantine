Quarantine: Mitigating Transient Execution Attacks with Physical Domain Isolation
=================================================================================

This repository contains the Quarantine prototypes as described in our
[RAID '23 paper](https://download.vusec.net/papers/quarantine_raid23.pdf).

The files [quarantine-kern.patch](quarantine-kern.patch) and
[quarantine-virt.patch](quarantine-virt.patch) contain the kernel patches,
relative to Linux 5.15, implementing the kernel-based and virtualization-based
prototypes respectively.

The kernel-based prototype was implemented by Manuel Wiesinger, the
virtualization-based prototype by Mathé Hertogh.

# Requirements

Quarantine requires a processor with at least two physical cores. The
virtualization-based prototype only supports AMD processors with AMD-V (i.e.
SVM) support.

# Test Quarantine using Docker

```
docker pull manufactory0/quarantine:latest
docker run -u root --device=/dev/kvm  --name quarantine -t -i --rm manufactory0/quarantine:latest
```

# Run Quarantine

## Run the Kernel-Isolation Prototype
```
./run_kern.sh
```

The number of servers can be configured via `/sys/kernel/sysiso/servers`

You can shut down the prototype (i.e. QEMU) using CTRL+A CTRL+X.

## Run the Virtualization-based Prototype

To try out the virtualization-based prototype, you will want a test virtual
machine. Let's download an Alpine VM.
```
wget -P home https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-virt-3.18.3-x86_64.iso
```

Launch the quarantined kernel in a virtual machine.
```
./run_virt.sh
```
In order to multiplex our terminal later on, let's start a `tmux` session.
```
tmux
```

Quarantine can be configured via `/sys/kernel/hypiso`, before any VMs have been
started yet.
```
echo 3 > /sys/kernel/hypiso/nr_guest_cpus
cat /sys/kernel/hypiso/core_config
```
This should show core 0 as the only host core and cores 1-3 as the guest cores.
Upon boot, Quarantine's physical domain isolation is turned off.
```
cat /sys/kernel/hypiso/hypiso_on
```
The same file allows you to turn it on.
```
echo 1 > /sys/kernel/hypiso/hypiso_on
cat /sys/kernel/hypiso/hypiso_on
```

Let's now launch a (nested) test virtual machine with 3 vCPUs and 2GB of memory.
```
qemu-system-x86_64 --smp 3 -m 2G -boot d -cdrom alpine-virt-3.18.3-x86_64.iso -enable-kvm -nographic
```
You can login using "root". This should give you a functioning Alpine VM.

Switch back to the host (Quarantine) kernel using `CTRL+B CTRL+C`, creating a
new `tmux` window. Quarantine spawned three runner threads for the 3 vCPUs of
the test VM.
```
dmesg | tail
```
Let's check that only those runners are running on guest CPUs, and all other
tasks are running on the host CPU.
```
ps H -F
```
The `PSR` column lists the CPU number that the task is running on.

You can shut down the prototype (i.e. QEMU) using `CTRL+A CTRL+X`.

# Build Quarantine manually

Commands were tested on Ubuntu 22.04.

## Dependencies

Make sure you have the necessary dependencies installed.
```
sudo apt install -y libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm zstd qemu-system-x86 debootstrap wget git python3-setuptools tmux unzip
```

We will use `virtme` to run the prototype in a virtualized environment.
```
git clone https://github.com/amluto/virtme.git
cd virtme && sudo ./setup.py install && cd ..
```

## Build the KVM Prototype

***Note that you applying `quarantine-kern.patch` and `quarantine-virt.patch` at the same source tree is not supported.***

Acquire the Linux 5.15 source code.
```
wget https://github.com/torvalds/linux/archive/refs/tags/v5.15.zip
unzip v5.15.zip
rm v5.15.zip
cd linux-5.15
```

Now choose to either apply the patch for the kernel-based prototype
```
git apply ../quarantine-kern.patch
```
or the one for the virtualization-based prototype.
```
git apply ../quarantine-virt.patch
```

Configure the kernel. We use the default config provided by `virtme`.
```
virtme-configkernel --defconfig
```
Make sure Quarantine is enabled.
```
scripts/config --enable HYPISO
```

Build the Quarantined kernel.
```
make -j`nproc`
cd ..
```

You can now install the kernel on your machine to run it baremetal. For testing,
it is easier to run it virtualized, which we will discuss next.

## Build the Kernel-Isolation Prototype

***Note that you applying `quarantine-kern.patch` and `quarantine-virt.patch` at the same source tree is not supported.***

Acquire Linux 5.15 and `cd linux-5.15`

Apply the patch
`patch patch -p1 < ../quarantine-kern.patch`

Generate a basic config
`virtme-configkernel --defconfig`

Configure Kernel-Isolation

```
scripts/config --enable SYSISO
scripts/config --enable SYSISO_USERSPACE
scripts/config --disable SYSISO_DEBUG
scripts/config --disable SYSISO_DEBUG_FTRACE
```

Build the Quarantined kernel.
```
make -j `nproc`
cd ..
```

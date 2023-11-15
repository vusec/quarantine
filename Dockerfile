FROM ubuntu:jammy AS base

# Setup Ubuntu 22.04
RUN apt update >/dev/null || true
RUN apt install -y libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm zstd qemu-system-x86 debootstrap wget git python3-setuptools tmux

# Add non-privileged user
RUN groupadd quarantine
RUN useradd -g quarantine -m quarantine
RUN chown -R quarantine:quarantine /home/quarantine
RUN usermod -a -G sudo quarantine

WORKDIR /home/quarantine

USER quarantine

# Install virtme
RUN git clone https://github.com/amluto/virtme.git
WORKDIR /home/quarantine/virtme

USER root
RUN ./setup.py install

USER quarantine
WORKDIR /home/quarantine/

# Fetch Linux
RUN wget https://kernel.org/pub/linux/kernel/v5.x/linux-5.15.tar.xz
RUN tar xf linux-5.15.tar.xz

# Prepare src dirs
RUN mv linux-5.15 linux-5.15-quarantine-virt
RUN cp -r linux-5.15-quarantine-virt linux-5.15-quarantine-kernel

# Build Quarantine for KVM
COPY ./quarantine-virt.patch .
WORKDIR /home/quarantine/linux-5.15-quarantine-virt
RUN patch -p1 < ../quarantine-virt.patch
RUN virtme-configkernel --defconfig
RUN scripts/config --enable HYPISO
RUN make -j `nproc`

WORKDIR /home/quarantine/
COPY ./run_virt.sh .
RUN mkdir virt_home
RUN wget -P virt_home https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-virt-3.18.3-x86_64.iso

# Build Quarantine for the kernel
COPY ./quarantine-kern.patch .
WORKDIR /home/quarantine/linux-5.15-quarantine-kernel
RUN patch -p1 < ../quarantine-kern.patch
RUN virtme-configkernel --defconfig
RUN scripts/config --enable SYSISO
RUN scripts/config --enable SYSISO_USERSPACE
RUN scripts/config --disable SYSISO_DEBUG
RUN scripts/config --disable SYSISO_DEBUG_FTRACE
RUN make -j `nproc`
RUN virtme-prep-kdir-mods

WORKDIR /home/quarantine/
COPY ./run_kern.sh .

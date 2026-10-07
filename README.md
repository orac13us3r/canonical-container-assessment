\# Canonical Container Images Technical Assessment



This repo contains a minimal multi architecture container image for a "Hello World" C application that is dynamically linked.



The final image is built FROM scratch and contains only the runtime files required to execute the application together with the entrypoint.



\# Repository Structure

```text

.

├── Dockerfile

├── hello.c

├── answers.txt

├── README.md

└── .github/

    └── workflows/

        └── build.yml



# Build and Run


docker build -t canonical-hello:local .
docker run --rm canonical-hello:local

Expected Output:

Hello World!

The Dockerfile supports both amd64 and arm64.

docker buildx build --platform linux/amd64 --load -t canonical-hello:amd64 .
docker buildx build --platform linux/arm64 --load -t canonical-hello:arm64 .

Run with 

docker run --rm --platform linux/amd64 canonical-hello:amd64
docker run --rm --platform linux/arm64 canonical-hello:arm64

Expected Output:

Hello World!


\# Implementation

The image is produced using a multi stage Docker build and the first Ubuntu stage compiles hello.c
The second Ubuntu stage constructs the minimal runtime filesystem and selects the correct libc runtime and ELF loader based on TARGETARCH.


for amd64:


/usr/lib/x86\_64-linux-gnu/libc.so.6
/lib64/ld-linux-x86-64.so.2

for arm64:

/usr/lib/aarch64-linux-gnu/libc.so.6
/lib/ld-linux-aarch64.so.1

The final stage starts FROM scratch and contains only the runtime filesystem and /HelloWorld, it also includes:

/etc/passwd
/tmp
/HelloWorld

/etc/passwd is copied from the Ubuntu base image and /tmp is created with mode 1777.

# CI/CD

The github actions workflow is defined in:

.github/workflows/build.yml

It uses Docker Buildx and QEMU to build and publish both linux/amd64 and linux arm64 images under a single OCI image index and the workflow publishes:

oneeyedk1ng/canonical-hello:latest
oneeyedk1ng/canonical-hello:<git-sha>

The published image can be inspected with:

docker buildx imagetools inspect oneeyedk1ng/canonical-hello:latest

The additional technical questions are answered in answers.txt.





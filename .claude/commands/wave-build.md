# Build Containers with Wave CLI

Build Docker/OCI containers using Seqera Wave cloud build service.

## Prerequisites

```bash
export TOWER_ACCESS_TOKEN=$(op read "op://Employee/Seqera Platform Prod/password")
```

## Build from Dockerfile

### Basic Build

```bash
wave -f Dockerfile --context . --await --tower-token "$TOWER_ACCESS_TOKEN"
```

### Build with Persistent Image (Recommended)

```bash
wave -f Dockerfile \
  --context . \
  --build-repo <registry/repo> \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

Example:

```bash
wave -f Dockerfile \
  --context . \
  --build-repo cr.seqera.io/seqera-services/igv-studio \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### Build with Layer Cache

Speed up rebuilds:

```bash
wave -f Dockerfile \
  --context . \
  --build-repo cr.seqera.io/seqera-services/my-image \
  --cache-repo cr.seqera.io/seqera-services/my-image-cache \
  --platform linux/amd64 \
  --freeze \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Build from Conda

### From Conda Packages

```bash
wave --conda-package bioconda::samtools=1.17 \
  --conda-package bioconda::bcftools=1.17 \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-tools \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### From Conda File

```bash
wave --conda-file environment.yml \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-env \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

### Custom Conda Channels

```bash
wave --conda-package samtools \
  --conda-channels conda-forge,bioconda,defaults \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-tools \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Augment Existing Image

Add files to an existing image:

```bash
wave -i ubuntu:22.04 \
  --layer ./my-files/ \
  --freeze \
  --build-repo cr.seqera.io/seqera-services/my-ubuntu \
  --await \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Mirror/Copy Images

Copy an image to another registry:

```bash
wave -i quay.io/biocontainers/samtools:1.17--h00cdaf9_0 \
  --mirror \
  --build-repo cr.seqera.io/seqera-services/samtools \
  --tower-token "$TOWER_ACCESS_TOKEN"
```

## Options Reference

| Option              | Description                                          |
| ------------------- | ---------------------------------------------------- |
| `-f <file>`         | Dockerfile to build                                  |
| `--context <dir>`   | Build context directory                              |
| `--build-repo`      | Registry for built images                            |
| `--cache-repo`      | Registry for layer cache                             |
| `--platform`        | Target platform (e.g., `linux/amd64`, `linux/arm64`) |
| `--freeze`          | Create persistent/immutable image                    |
| `--await [timeout]` | Wait for build (default 15min, e.g., `--await 30m`)  |
| `-i <image>`        | Base image to augment                                |
| `--layer <dir>`     | Directory to add as layer                            |
| `--conda-package`   | Conda package(s) to install                          |
| `--conda-file`      | Conda environment file                               |
| `--conda-channels`  | Conda channels (default: conda-forge,bioconda)       |
| `--mirror`          | Copy image to build-repo                             |
| `--tower-token`     | Seqera Platform token                                |

## Output

Without `--freeze`:

```
wave.seqera.io/wt/abc123/ubuntu:latest
```

With `--freeze`:

```
cr.seqera.io/seqera-services/my-image:1a2b3c4d
```

## Advantages

- **No local Docker** - builds in Seqera cloud
- **Native linux/amd64** - no emulation on Apple Silicon
- **Conda integration** - direct package installation
- **Layer caching** - faster rebuilds with `--cache-repo`
- **Security scanning** - with `--scan-mode required`

## Troubleshooting

### Build Context Too Large

Create/update `.dockerignore`:

```
.git
test-data
*.md
node_modules
```

### Timeout Issues

Increase timeout for large builds:

```bash
--await 30m
```

### Authentication Errors

Verify token is set:

```bash
echo $TOWER_ACCESS_TOKEN | head -c 10
```

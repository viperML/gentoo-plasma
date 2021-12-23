# [viperML/gentoo-plasma @ Docker Hub](https://hub.docker.com/repository/docker/viperml/gentoo-plasma/general)

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/viperml/gentoo-plasma/Build%20and%20push%20to%20registry)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/viperml/gentoo-plasma/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/viperml/gentoo-plasma)


Source for docker image that contains latest stage3, whith KDE plasma desktop systemd amd64 profile, and plasma-meta. I use it in [my overlay](https://github.com/viperML/viperML-overlay) to build package updates, whithout having to build the entire desktop framework each time.

It contains some basic cli tools, such as git, repoman, gentoolkit, flaggie and jq. Feel free to write a PR if you want something else bundled in.

## Sample usage in github workflows

```yaml
on:
  push:

jobs:
  build-foobar:
    runs-on: ubuntu-latest
    container: docker://viperml/gentoo-plasma
    steps:
      - uses: actions/checkout@v2
      - run: ebuild foo/bar/*.ebuild clean merge
```

## Forking

- Set up `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` in your repository secrets

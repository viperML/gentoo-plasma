# Based on https://github.com/gentoo/gentoo-docker-images/blob/8e49c8eec53097a7c9c9e5667064bc01f684a1ae/stage3.Dockerfile
ARG BUILDER
FROM --platform=$BUILDPLATFORM ${BUILDER:-alpine:latest} as builder

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX=desktop-systemd
ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG SIGNING_KEY="0xBB572E0E2D182910"
ARG MAKEOPTS="-j1"

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}"
RUN apk --no-cache add ca-certificates gnupg tar wget xz git
RUN STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-${MICROARCH}-${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')" \
    && echo "STAGE3PATH:" $STAGE3PATH \
    && STAGE3="$(basename ${STAGE3PATH})" \
    && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS" "${DIST}/${STAGE3PATH}.asc" \
    && gpg --list-keys \
    && echo "honor-http-proxy" >> ~/.gnupg/dirmngr.conf \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && gpg --keyserver hkps://keys.gentoo.org --recv-keys ${SIGNING_KEY} \
    && gpg --verify "${STAGE3}.asc" \
    && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS | sha512sum -c \
    && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
    && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
    && echo 'UTC' > etc/timezone \
    && rm ${STAGE3}.DIGESTS ${STAGE3}.CONTENTS.gz ${STAGE3} \
    && git clone --depth 1 https://github.com/gentoo-mirror/gentoo var/db/repos/gentoo
# Basic stage 3 ready
# use alpine's git because stage3 comes without git

FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /

RUN mkdir --parents /etc/portage/repos.conf
COPY ./gentoo.conf /etc/portage/repos.conf/gentoo.conf
# repos configured and downloaded
RUN eselect profile set default/linux/amd64/17.1/desktop/plasma/systemd \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && eselect locale set en_US.utf8 \
    && env-update \
    && echo "EMERGE_DEFAULT_OPTS=\"--ask=n --quiet-build=y --binpkg-respect-use=y --getbinpkg=y --with-bdeps=y\"" >> /etc/portage/make.conf \
    && echo "PORTAGE_BINHOST=\"https://gentoo.osuosl.org/experimental/amd64/binpkg/default/linux/17.1/x86-64/\"" >> /etc/portage/make.conf
# system configured
RUN emerge --update --deep --changed-use @world \
    && rm -rf /var/cache/distfiles/* \
    && rm -rf /var/cache/binpkgs/*
# stage3 packages updated
RUN emerge kde-plasma/plasma-meta \
    && rm -rf /var/cache/distfiles/* \
    && rm -rf /var/cache/binpkgs/*
RUN emerge --depclean
# plasma installed

RUN emerge dev-vcs/git app-portage/repoman app-portage/flaggie app-misc/jq app-portage/gentoolkit \
    && rm -rf /var/cache/distfiles/* \
    && rm -rf /var/cache/binpkgs/*
# extra tools installed

CMD ["/bin/bash"]

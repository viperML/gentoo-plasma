# Based on https://github.com/gentoo/gentoo-docker-images/blob/8e49c8eec53097a7c9c9e5667064bc01f684a1ae/stage3.Dockerfile
ARG BUILDER
FROM --platform=$BUILDPLATFORM ${BUILDER:-alpine:latest} as builder

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX=desktop-systemd
ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG SIGNING_KEY="0xBB572E0E2D182910"
ARG PROC=1

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}"
RUN apk --no-cache add ca-certificates gnupg tar wget xz
RUN STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-${MICROARCH}-${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')" \
    && echo "STAGE3PATH:" $STAGE3PATH \
    && STAGE3="$(basename ${STAGE3PATH})" \
    && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS.asc" \
    && gpg --list-keys \
    && echo "honor-http-proxy" >> ~/.gnupg/dirmngr.conf \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && gpg --keyserver hkps://keys.gentoo.org --recv-keys ${SIGNING_KEY} \
    && gpg --verify "${STAGE3}.DIGESTS.asc" \
    && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c \
    && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
    && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
    && echo 'UTC' > etc/timezone \
    && rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS.gz ${STAGE3}
RUN mkdir --parents etc/portage/repos.conf
RUN ln -s usr/share/portage/config/repos.conf etc/portage/repos.conf/gentoo.conf
#  && emerge --sync --quiet --ask=n

FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /
CMD ["/bin/bash"]

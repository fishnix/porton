# Specifies the builder image to use for building krakend plugins
ARG BUILDER_IMAGE=krakend/builder

# Specifies the krakend gateway image
ARG IMAGE=devopsfaith/krakend

# Specifies the krakend image tag to use. The tag for the builder and the
# krakend images should match,a and so, this is handled via a single
# variable.
# renovate: depName=devopsfaith/krakend
ARG IMAGE_TAG=2.3.0

# Plugin build
FROM $BUILDER_IMAGE:$IMAGE_TAG AS pluginbuilder

WORKDIR /go/src/porton/lib

# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

# Run the plugin builder
RUN go build -buildmode=plugin -o porton.so .

# Gateway build
FROM $IMAGE:$IMAGE_TAG

# For more information see https://www.krakend.io/docs/enterprise/configuration/flexible-config/
ENV FC_ENABLE=1

# Ensure the plugins directory exists
RUN mkdir -p /opt/krakend/plugins 

# Copy plugins from the pluginbuilder
COPY --from=pluginbuilder /go/src/porton/lib /opt/krakend/plugins

# Run as non-root user
USER 1000

ENTRYPOINT [ "/usr/bin/krakend" ]
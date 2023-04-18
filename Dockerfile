FROM kong/kong-gateway:3.2.2.0
USER root
RUN apt update && apt upgrade -y && apt install -y build-essential unzip
RUN luarocks install kong-plugin-usagelogger
USER kong

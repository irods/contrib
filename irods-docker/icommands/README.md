# docker-iRODS-iCommands

The docker iRODS Image is an easy distributable installation of the iCommands CLI. It can be used for testing, teaching and production.

## Usage

### Build image
```
cd icommands && \
docker build -t irods/icommands:4.2.0 --rm .
```

### Run image
To run this docker image, simply do
```
docker run -ti irods/icommands:4.2.0
```


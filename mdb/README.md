# MillenniumDB

[MillenniumDB](https://github.com/MillenniumDB/MillenniumDB) is a graph oriented database management system developed by the [Millennium Institute for Foundational Research on Data (IMFD)](https://imfd.cl/).

MillenniumDB was created because we though the existent graph models were not enough to represent efficiently the real world data as a graph.

Our main objective with this project is to be a fully functional, easy-to-extend system that serves as the basis for testing new techniques and algorithms related to databases and graphs.

## Getting started

### TLDR

Install dependencies:

- Only Millennium: `mdb/install_dependencies.sh`
- All databases: `script/install_dependencies.sh`

Install new binaries (also installs dependencies): 

- `mdb/get.sh`

Run queries for example graph examples:

- `mdb/init-and-load.sh && mdb/run.sh && mdb/stop.sh`
- `scripts/run_bench.sh --sf=example --dbs=mdb:MillenniumDB`

### Install dependencies

To only install the dependencies for MillenniumDB, you can run `mdb/install_dependencies.sh`. This is also achieved by running `scripts/install_dependencies.sh`, which install the dependencies for all databases.

### Build binaries

You can build and install the latest version of MillenniumDB using the following:

- `mdb/get.sh`

This also installs all needed dependencies.

### Loading, running and stopping

First select the scaling factor to execute the queries for. To change the default scaling factor `example` to `<sf>`, run:

- `export SF=<sf>`

Loading a graph is achieved by executing `mdb/init-and-load.sh`. This in turn calls `mdb/pre-load.sh`, `load.sh` and `mdb/post-load.sh`. If none or not all of the binaries are present during pre-loading, they are automatically build and installed using `mdb/get.sh`.
MillenniumDB is started in a separate screen session.

The queries are then executed with `mdb/run.sh`.

Finally, use `mdb/stop.sh` to stop MillenniumDB and start the clean-up.

Another method to load, run and stop is to use the following:

- `scripts/run_bench.sh --dbs=mdb:MillenniumDB`

Use `scripts/run_bench.sh --help`  for more info.

## Caching

Before MillenniumDB can load the data, it needs to transform it to a different format. To speed up this process during the loading, we additionally support caching of the graph files. This feature is enabled by default, can be turned off by setting `MILLENNIUMDB_CACHE` to `0` in `mdb/vars.sh`.

To clear all cache, use `mdb/clear-cache.sh --all`, and to clear the cache for scaling factor `<sf>`, use `mdb/clear-cache --sf=<sf>`.
Use `mdb/clear-cache.sh --help` for more info.

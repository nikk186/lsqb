# AvantGraph

[AvantGraph](http://avantgraph.io/) is a state of the art graph database currently in development at the [Technical University Eindhoven (TU/e)](https://www.tue.nl/en/).
Note that binaries are not included, and can must be build from the (private) repo.

## Getting started

### TLDR

Install dependencies:

- Only AvantGraph: `avg/install_dependencies.sh`
- All databases: `script/install_dependencies.sh`

Build and install binaries (requires authentication, also installs dependencies): 

- `avg/get.sh`

Run queries for example graph examples (install dependencies and builds if needed):

- `avg/init-and-load.sh && avg/run.sh && avg/stop.sh`
- `scripts/run_bench.sh --sf=example --dbs=avg:AvantGraph`

### Install dependencies

To only install the dependencies for AvantGraph, you can run `avg/install_dependencies.sh`. This is also achieved by running `scripts/install_dependencies.sh`, which install the dependencies for all databases.

### Build binaries

AvantGraph is currently under development and not yet available to the public.
If you are authorized to the AvantGraph repo, you can build and install the binaries using `avg/get.sh`. Provide any argument to disable user interaction (e.g. `avg/get.sh -`). Running this script also installs the needed dependencies.

### Loading, running and stopping

First select the scaling factor to execute the queries for. To change the default scaling factor `example` to `<sf>`, run:

- `export SF=<sf>`

Loading a graph is achieved by executing `avg/init-and-load.sh`. This in turn calls `avg/pre-load.sh`, `load.sh` and `avg/post-load.sh`. If none or not all of the binaries are present during pre-loading, they are automatically build and installed using `avg/get.sh`.
AvantGraph currently doesn't run as a separate service, so the loading only prepares the data.

The queries are then executed with `avg/run.sh`.

Finally, run `avg/stop.sh` to start the clean-up.

Another method to load, run and stop is to use the following:

- `scripts/run_bench.sh --dbs=avg:AvantGraph`

Use `scripts/run_bench.sh --help`  for more info.

## Caching

To reduce the loading times, we additionally support caching of the graph files. This feature is enabled by default, can be turned off by setting `AVANTGRAPH_CACHE` to `0` in `avg/vars.sh`.

To clear all cache, use `avg/clear-cache.sh --all`, and to clear the cache for scaling factors `<sf>`, use `avg/clear-cache --sf=<sf>`.
Use `avg/clear-cache.sh --help` for more info.

## Plan selection

There are multiple ways to plan the execution of a query. The query planner is currently under development, and thus you can to test the actual performance of AvantGraph by using custom plans. The plans to use can be changed by changing `AVANTGRAPH_SRC_PLANS` in `avg/vars.sh` to one of `${AVANGRAPH_DIR}/plans[_opt{1,2,3}]`.
`plans` contains the plans currently generated using the current planner, `plans_opt{1,2}` have trivial optimizations, and `plans_3` is fully optimized.

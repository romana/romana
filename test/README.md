# Cluster Tests

Verification scripts to execute on a cluster after it has been installed.

## Running Tests

Tests are usually invoked by the host running `romana-setup`.
After completing an installation (eg: `./romana-setup ... install`, you execute the tests with `./romana-setup ... test`).
At the end, a summary of the results will be provided. Example output is:
```
2016-07-12 03:10:01 (ip-192-168-99-10:clustertests) Test #1: Check that Kubernetes services are running on master : PASSED
2016-07-12 03:10:01 (ip-192-168-99-10:clustertests) Test #2: Check that Romana services are running on master : PASSED
2016-07-12 03:10:01 (ip-192-168-99-10:clustertests) Test #3: Check that Kubernetes services are running on minion : PASSED
2016-07-12 03:10:01 (ip-192-168-99-10:clustertests) Test #4: Check that Romana services are running on minion : PASSED
2016-07-12 03:10:02 (ip-192-168-99-10:clustertests) Test #6: Pull docker containers used in later tests : PASSED
2016-07-12 03:10:23 (ip-192-168-99-10:clustertests) Test #8: Check namespace creation triggers romana tenant creation : PASSED
2016-07-12 03:10:24 (ip-192-168-99-10:clustertests) Test #7: Check that kubernetes can launch some pods : PASSED
...
```

If tests are failing, they can be executed directly on the cluster node:
```bash
cd /var/tmp/cluster-tests
./clustertests -l ... -l ...
```

(The values to use depend on the test that failed. You can usually see it in the output from running `romana-setup`.)

## Writing Tests

### General Notes

Each test should

- print a summary of whether it succeeded/failed
- exit with zero (success) or non-zero (failure)
- support a -v option for verbose mode
- be executable, with an appropriate shebang and such
- clean up after itself, if possible

### Invocation

Tests are executed by the `clustertests` script, which uses a test configuration file and labels specified on the command-line.

Eg: when running `./clustertests -l foo -l bar`, the config file is parsed, and any tests with the labels "foo" and "bar" are executed.

When launched with verbose mode (`-v`) this parameter is passed to each test command, and should result in detailed output.

The test configuration file is made up of blocks containing labels/values. Each block is separated by blank lines.
Eg:
```
command: services_running
args: romana-agent
description: Check that Romana services are running on compute nodes
labels: romana-agent, services

command: run-vms-each-host
description: Check that VMs can be created on each compute node
labels: openstack, endpoints
```

Each block must contain a `command` and `labels`, and optionally `args` and `description`.

When run from `romana-setup`, execution will stop at the first error.
This is helpful because it means simple tests need to pass before attempting more complex tests.

### Adding additional tests

When adding new tests, it is usually necessary to write a script for it to support the expected behavior for exit status and verbose options.

If additional tools are required, these should be added to the installer. (The test stage does not install new packages.)

Once written, it can be added to the appropriate `tests` file (eg: `test/openstack-cluster/tests` or `test/kubernetes-cluster/tests`), providing the command/description/args/labels required.
If it is reusing existing labels, then no additional changes will be necessary. However, if new labels are being used, then it needs to be added to `romana-install/tests.< stck type>.yml` to be launched.

Tests should be independent, repeatable and reliable. So consideration should be given to any changed state on the cluster nodes and deleting things that are created during execution.

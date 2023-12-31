# gpstart 

Starts a Greenplum Database system.

## <a id="section2"></a>Synopsis 

```
gpstart [-d <master_data_directory>] [-B <parallel_processes>] [-R]
        [-m] [-y] [-a] [-t <timeout_seconds>] [-l <logfile_directory>] 
        [--skip-heap-checksum-validation]
        [-v | -q]

gpstart -? | -h | --help 

gpstart --version
```

## <a id="section3"></a>Description 

The `gpstart` utility is used to start the Greenplum Database server processes. When you start a Greenplum Database system, you are actually starting several `postgres` database server listener processes at once \(the master and all of the segment instances\). The `gpstart` utility handles the startup of the individual instances. Each instance is started in parallel.

As part of the startup process, the utility checks the consistency of heap checksum setting among the Greenplum Database master and segment instances, either enabled or deactivated on all instances. If the heap checksum setting is different among the instances, an error is returned and Greenplum Database does not start. The validation can be deactivated by specifying the option `--skip-heap-checksum-validation`. For more information about heap checksums, see [Enabling High Availability and Data Consistency Features](../../admin_guide/highavail/topics/g-enabling-high-availability-features.html) in the *Greenplum Database Administrator Guide*.

> **Note** Before you can start a Greenplum Database system, you must have initialized the system using `gpinitsystem`. Enabling or deactivating heap checksums is set when you initialize the system and cannot be changed after initialization.

If the Greenplum Database system is configured with a standby master, and `gpstart` does not detect it during startup, `gpstart` displays a warning and lets you cancel the startup operation.

-   If the `-a` option \(deactivate interactive mode prompts\) is not specified, `gpstart` displays and logs these messages:

    ```
    Standby host is unreachable, cannot determine whether the standby is currently acting as the master. Received error: <error>
    Continue only if you are certain that the standby is not acting as the master.
    ```

    It also displays this prompt to continue startup:

    ```
    Continue with startup Yy|Nn (default=N):
    ```

-   If the `-a` option is specified, the utility does not start the system. The messages are only logged, and `gpstart` adds this log message:

    ```
    Non interactive mode detected. Not starting the cluster. Start the cluster in interactive mode.
    ```


If the standby master is not accessible, you can start the system and troubleshoot standby master issues while the system is available.

## <a id="section4"></a>Options 

-a
:   Do not prompt the user for confirmation. Deactivates interactive mode.

-B parallel\_processes
:   The number of segments to start in parallel. If not specified, the utility will start up to 64 parallel processes depending on how many segment instances it needs to start.

-d master\_data\_directory
:   Optional. The master host data directory. If not specified, the value set for `$MASTER_DATA_DIRECTORY` will be used.

-l logfile\_directory
:   The directory to write the log file. Defaults to `~/gpAdminLogs`.

-m
:   Optional. Starts the master instance only, which may be useful for maintenance tasks. This mode only allows connections to the master in utility mode. For example:

:   `PGOPTIONS='-c gp_session_role=utility' psql`

:   The consistency of the heap checksum setting on master and segment instances is not checked.

-q
:   Run in quiet mode. Command output is not displayed on the screen, but is still written to the log file.

-R
:   Starts Greenplum Database in restricted mode \(only database superusers are allowed to connect\).

--skip-heap-checksum-validation
:   During startup, the utility does not validate the consistency of the heap checksum setting among the Greenplum Database master and segment instances. The default is to ensure that the heap checksum setting is the same on all instances, either enabled or deactivated.

> **Caution** Starting Greenplum Database without this validation could lead to data loss. Use this option to start Greenplum Database only when it is necessary to ignore the heap checksum verification errors to recover data or to troubleshoot the errors.

-t timeout\_seconds
:   Specifies a timeout in seconds to wait for a segment instance to start up. If a segment instance was shutdown abnormally \(due to power failure or killing its `postgres` database listener process, for example\), it may take longer to start up due to the database recovery and validation process. If not specified, the default timeout is 600 seconds.

-v
:   Displays detailed status, progress and error messages output by the utility.

-y
:   Optional. Do not start the standby master host. The default is to start the standby master host and synchronization process.

-? \| -h \| --help
:   Displays the online help.

--version
:   Displays the version of this utility.

## <a id="section5"></a>Examples 

Start a Greenplum Database system:

```
gpstart
```

Start a Greenplum Database system in restricted mode \(only allow superuser connections\):

```
gpstart -R
```

Start the Greenplum master instance only and connect in utility mode:

```
gpstart -m 
PGOPTIONS='-c gp_session_role=utility' psql
```

## <a id="section6"></a>See Also 

[gpstop](gpstop.html), [gpinitsystem](gpinitsystem.html)


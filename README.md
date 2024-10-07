# YugabyteDB JDBC Driver
This is a distributed JDBC driver for YugabyteDB SQL. This driver is based on the [PostgreSQL JDBC Driver](https://github.com/pgjdbc/pgjdbc).

## Features

This JDBC driver has the following features:

### Cluster Awareness to eliminate need for a load balancer

This driver adds a `YBClusterAwareDataSource` that requires only an initial _contact point_ for the YugabyteDB cluster, using which it discovers the rest of the nodes. Additionally, it automatically learns about the nodes being started/added or stopped/removed. Internally the driver keeps track of number of connections it has created to each server endpoint and every new connection request is connected to the least loaded server as per the driver's view.


### Topology Awareness to enable geo-distributed apps

This is similar to 'Cluster Awareness' but uses those servers which are part of a given set of geo-locations specified by _topology-keys_.

### Shard awareness for high performance

> **NOTE:** This feature is still in the design phase.

### Connection Properties added for load balancing

- _load-balance_ - Starting with version 42.3.5-yb-8, it expects one of **false, any (same as true), only-primary, only-rr, prefer-primary and prefer-rr** as its possible values. In `YBClusterAwareDataSource` load balancing is `true` by default. However, when using the `DriverManager.getConnection()` API the 'load-balance' property is considered to be `false` by default.
  - _false_ - No connection load balancing. Behaviour is similar to vanilla PGJDBC driver
  - _any_ - Same as value _true_. Distribute connections equally across all nodes in the cluster, irrespective of its type (`primary` or `read-replica`)
  - _only-primary_ - Create connections equally across only the primary nodes of the cluster
  - _only-rr_ - Create connections equally across only the read-replica nodes of the cluster
  - _prefer-primary_ - Create connections equally across primary cluster nodes. If none available, on any available read replica node in the cluster
  - _prefer-rr_ - Create connections equally across read replica nodes of the cluster. If none available, on any available primary cluster node
- _topology-keys_  - It takes a comma separated geo-location values. A single geo-location can be given as 'cloud.region.zone'. Multiple geo-locations too can be specified, separated by comma (`,`).
- _yb-servers-refresh-interval_ - Time interval, in seconds, between two attempts to refresh the information about cluster nodes. Default is 300 seconds. Valid values are integers between 0 and 600. Value 0 means refresh for each connection request. Any value outside this range is ignored and the default is used.
- _fallback-to-topology-keys-only_ - Decides if the driver can fall back to nodes outside of the given placements for new connections, if the nodes in the given placements are not available. Value `true` means stick to explicitly given placements for fallback, else fail. Value `false` means fall back to entire cluster nodes when nodes in the given placements are unavailable. Default is `false`. It is ignored if `topology-keys` is not specified or `load-balance` is set to either `prefer-primary` or `prefer-rr`.
- _failed-host-reconnect-delay-secs_ - When the driver cannot connect to a server, it marks it as _failed_ with a timestamp. Later, whenever it refreshes the server list via `yb_servers()`, if it sees the failed server in the response, it marks the server as UP only if the time specified via this property has elapsed since the time it was last marked as a failed host. Default is 5 seconds.

Please refer to the [Use the Driver](#use-the-driver) section for examples.

### Status
[![License](https://img.shields.io/badge/License-BSD--2--Clause-blue.svg)](https://opensource.org/licenses/BSD-2-Clause)

[![Maven Central](https://img.shields.io/maven-central/v/com.yugabyte/jdbc-yugabytedb)](https://central.sonatype.com/artifact/com.yugabyte/jdbc-yugabytedb)

> **Note:** PgJDBC versions since 42.8.0 are not guaranteed to work with PostgreSQL older than 9.1.

## Get the Driver

### From Maven

Add the following lines to your maven project in pom.xml file (Use the latest version available),
```
<dependency>
  <groupId>com.yugabyte</groupId>
  <artifactId>jdbc-yugabytedb</artifactId>
  <version>${driver.version}</version>
</dependency>
```

You can visit to this link for the latest version of the driver: https://search.maven.org/artifact/com.yugabyte/jdbc-yugabytedb

[mvn-search]: https://central.sonatype.com/artifact/com.yugabyte/jdbc-yugabytedb "Search on Maven Central"

### Build locally

0. Build environment

   gpgsuite needs to be present on the machine where build is performed.
   ```
   https://gpgtools.org/
   ```
   Please install gpg and create a key.

1. Clone this repository.

    ```
    git clone https://github.com/yugabyte/pgjdbc.git && cd pgjdbc
    ```

2. Build and install into your local maven folder.

    ```
     ./gradlew publishToMavenLocal -x test -x checkstyleMain
    ```

3. Finally, use it by adding the lines below to your project. (Use the latest version available)

    ```xml
    <dependency>
        <groupId>com.yugabyte</groupId>
        <artifactId>jdbc-yugabytedb</artifactId>
        <version>${driver.version}</version>
    </dependency> 
    ```
> **Note:** You need to have installed 2.7.2.0-b0 or above version of YugabyteDB on your system for load balancing to work.

## Connection Properties

| Property                      | Type |         Default         | Description                                                                                                                                                                                                                                                                                                                                     |
|-------------------------------| -- |:-----------------------:|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| user                          | String |          null           | The database user on whose behalf the connection is being made.                                                                                                                                                                                                                                                                               |
| password                      | String |          null           | The database user's password.                                                                                                                                                                                                                                                                                                                 |
| options                       | String |          null           | Specify 'options' connection initialization parameter.                                                                                                                                                                                                                                                                                        |
| service                       | String |          null           | Specify 'service' name described in pg_service.conf file. References: [The Connection Service File](https://www.postgresql.org/docs/current/libpq-pgservice.html) and [The Password File](https://www.postgresql.org/docs/current/libpq-pgpass.html). 'service' file can provide all properties including 'hostname=', 'port=' and 'dbname='. |
| ssl                           | Boolean |          false          | Control use of SSL (true value causes SSL to be required)                                                                                                                                                                                                                                                                                    |
| sslfactory                    | String | org.postgresql.ssl.LibPQFactory | Provide a SSLSocketFactory class when using SSL.                                                                                                                                                                                                                                                                                      |
| sslfactoryarg (deprecated)    | String |          null           | Argument forwarded to constructor of SSLSocketFactory class.                                                                                                                                                                                                                                                                                  |
| sslmode                       | String |         prefer          | Controls the preference for opening using an SSL encrypted connection.                                                                                                                                                                                                                                                                        |
| sslcert                       | String |          null           | The location of the client's SSL certificate                                                                                                                                                                                                                                                                                                  |
| sslkey                        | String |          null           | The location of the client's SSL key. `.p12`/`.pfx` select PKCS-12, `.pem` selects PEM, and `.der` selects DER/PKCS-8. For other extensions, the first 64 KiB is scanned for a PEM private-key header, otherwise DER/PKCS-8 is used. The PKCS-12 alias must be `user`.                                                                      |
| sslrootcert                   | String |          null           | The location of the root certificate for authenticating the server.                                                                                                                                                                                                                                                                           |
| sslhostnameverifier           | String |          null           | The name of a class (for use in [Class.forName(String)](https://docs.oracle.com/javase/6/docs/api/java/lang/Class.html#forName%28java.lang.String%29)) that implements javax.net.ssl.HostnameVerifier and can verify the server hostname.                                                                                                     |
| sslpasswordcallback           | String |          null           | The name of a class (for use in [Class.forName(String)](https://docs.oracle.com/javase/6/docs/api/java/lang/Class.html#forName%28java.lang.String%29)) that implements javax.security.auth.callback.CallbackHandler and can handle PasswordCallback for the ssl password.                                                                     |
| sslpassword                   | String |          null           | The password for the client's ssl key (ignored if sslpasswordcallback is set)                                                                                                                                                                                                                                                                 |
| sslnegotiation                | String |        postgres         | Determines if ALPN ssl negotiation will be used or not. Set to `direct` to choose ALPN.                                                                                                                                                                                                                                                       |
| sendBufferSize                | Integer |           -1            | Socket write buffer size                                                                                                                                                                                                                                                                                                                     |
| maxSendBufferSize             | Integer |        65536            | Maximum amount of bytes buffered before sending to the backend. pgjdbc uses `least(maxSendBufferSize, greatest(8192, SO_SNDBUF))` to determine the buffer size.                                                                                                                                                                              |
| receiveBufferSize             | Integer |           -1            | Socket read buffer size                                                                                                                                                                                                                                                                                                                      |
| logServerErrorDetail          | Boolean |          true           | Allows server error detail (such as sql statements and values) to be logged and passed on in exceptions.  Setting to false will mask these errors so they won't be exposed to users, or logs.                                                                                                                                                |
| allowEncodingChanges          | Boolean |          false          | Allow for changes in client_encoding                                                                                                                                                                                                                                                                                                         |
| logUnclosedConnections        | Boolean |          false          | When connections that are not explicitly closed are garbage collected, log the stacktrace from the opening of the connection to trace the leak source                                                                                                                                                                                        |
| binaryTransfer                | Boolean |          true           | Enable binary transfer for supported built-in types if possible. Setting this to false disables any binary transfer unless it's individually activated for each type with `binaryTransferEnable`. Whether it is possible to use binary transfer at all depends on server side prepared statements (see `prepareThreshold` ).                 |
| binaryTransferEnable          | String |           ""            | Comma separated list of types to enable binary transfer. Either OID numbers or names.                                                                                                                                                                                                                                                         |
| binaryTransferDisable         | String |           ""            | Comma separated list of types to disable binary transfer. Either OID numbers or names. Overrides values in the driver default set and values set with binaryTransferEnable.                                                                                                                                                                   |
| prepareThreshold              | Integer |            5            | Determine the number of `PreparedStatement` executions required before switching over to use server side prepared statements. The default is five, meaning start using server side prepared statements on the fifth execution of the same `PreparedStatement` object. A value of -1 activates server side prepared statements and forces binary transfer for enabled types (see `binaryTransfer` ). |
| preparedStatementCacheQueries | Integer |           256           | Specifies the maximum number of entries in per-connection cache of prepared statements. A value of 0 disables the cache.                                                                                                                                                                                                                     |
| preparedStatementCacheSizeMiB | Integer |            5            | Specifies the maximum size (in megabytes) of a per-connection prepared statement cache. A value of 0 disables the cache.                                                                                                                                                                                                                     |
| defaultRowFetchSize           | Integer |            0            | Positive number of rows that should be fetched from the database when more rows are needed for ResultSet by each fetch iteration                                                                                                                                                                                                             |
| queryTimeout                  | Integer |            0            | The timeout value in seconds that the driver will wait for a query to execute if not explicitly set by [Statement.setQueryTimeout(int)](https://docs.oracle.com/javase/6/docs/api/java/sql/Statement.html#setQueryTimeout%28int%29)). A value of 0 means no timeout.                                                                         |
| loginTimeout                  | Integer |            0            | Specify how long in seconds max(2147484) to wait for establishment of a database connection.                                                                                                                                                                                                                                                 |
| connectTimeout                | Integer |           10            | The timeout value in seconds max(2147484) used for socket connect operations.                                                                                                                                                                                                                                                                |
| socketTimeout                 | Integer |            0            | The timeout value in seconds max(2147484) used for socket read operations.                                                                                                                                                                                                                                                                   |
| cancelSignalTimeout           | Integer |            10           | The timeout that is used for sending cancel command.                                                                                                                                                                                                                                                                                         |
| sslResponseTimeout            | Integer |          5000           | Socket timeout in milliseconds waiting for a response from a request for SSL upgrade from the server.                                                                                                                                                                                                                                        |
| tcpKeepAlive                  | Boolean |          false          | Enable or disable TCP keep-alive.                                                                                                                                                                                                                                                                                                            |
| tcpNoDelay                    | Boolean |          true           | Enable or disable TCP no delay.                                                                                                                                                                                                                                                                                                              |
| ApplicationName               | String  | PostgreSQL JDBC Driver   | The application name (require server version >= 9.0). If assumeMinServerVersion is set to >= 9.0 this will be sent in the startup packets, otherwise after the connection is made                                                                                                                                                           |
| readOnly                      | Boolean |          false          | Puts this connection in read-only mode                                                                                                                                                                                                                                                                                                       |
| readOnlyMode                  | String |          transaction   | Specifies the behavior when a connection is set to be read only, possible values: ignore, transaction, always                                                                                                                                                                                                                                  |
| disableColumnSanitiser        | Boolean |          false          | Enable optimization that disables column name sanitiser                                                                                                                                                                                                                                                                                      |
| assumeMinServerVersion        | String |          null           | Assume the server is at least that version                                                                                                                                                                                                                                                                                                    |
| currentSchema                 | String |          null           | Specify the schema (or several schema separated by commas) to be set in the search-path                                                                                                                                                                                                                                                       |
| targetServerType              | String |           any           | Specifies what kind of server to connect, possible values: any, master, slave (deprecated), secondary, preferSlave (deprecated), preferSecondary, preferPrimary                                                                                                                                                                               |
| hostRecheckSeconds            | Integer |           10            | Specifies period (seconds) after which the host status is checked again in case it has changed                                                                                                                                                                                                                                               |
| loadBalanceHosts              | Boolean |          false          | If disabled hosts are connected in the given order. If enabled hosts are chosen randomly from the set of suitable candidates                                                                                                                                                                                                                 |
| socketFactory                 | String |          null           | Specify a socket factory for socket creation                                                                                                                                                                                                                                                                                                  |
| socketFactoryArg (deprecated) | String |          null           | Argument forwarded to constructor of SocketFactory class.                                                                                                                                                                                                                                                                                     |
| classLoaderStrategy           | String |      driver-first       | Order in which classloaders are searched when loading a class named by a connection property; values are driver-first (default), driver, context-first                                                                                                                                                                                       |
| autosave                      | String |          never          | Specifies what the driver should do if a query fails, possible values: always, never, conservative                                                                                                                                                                                                                                            |
| cleanupSavepoints             | Boolean |          false          | In Autosave mode the driver sets a SAVEPOINT for every query. It is possible to exhaust the server shared buffers. Setting this to true will release each SAVEPOINT at the cost of an additional round trip.                                                                                                                                 |
| preferQueryMode               | String |        extended         | Specifies which mode is used to execute queries to database, possible values: extended, extendedForPrepared, extendedCacheEverything, simple                                                                                                                                                                                                  |
| reWriteBatchedInserts         | Boolean |          false          | Enable optimization to rewrite and collapse compatible INSERT statements that are batched.                                                                                                                                                                                                                                                   |
| reWriteBatchedInsertsSize     | Integer |            0            | Maximum number of rows merged into a single multi-values INSERT when reWriteBatchedInserts is enabled. Rounded down to a power of two and capped at 32768 rows (and, with the extended protocol, at 65535/parametersPerRow). A value of 0, the default, uses that maximum.                                                                      |
| escapeSyntaxCallMode          | String |         select          | Specifies how JDBC escape call syntax is transformed into underlying SQL (CALL/SELECT), for invoking procedures or functions (requires server version >= 11), possible values: select, callIfNoReturn, call                                                                                                                                   |
| maxResultBuffer               | String |          null           | Specifies size of result buffer in bytes, which can't be exceeded during reading result set. Can be specified as particular size (i.e. "100", "200M" "2G") or as percent of max heap memory (i.e. "10p", "20pct", "50percent")                                                                                                                |
| gssLib                        | String |          auto           | Permissible values are auto (default, see below), sspi (force SSPI) or gssapi (force GSSAPI-JSSE).                                                                                                                                                                                                                                            |
| gssResponseTimeout            | Integer |          5000           | Socket timeout in milliseconds waiting for a response from a request for GSS encrypted connection from the server.                                                                                                                                                                                                                           |
| gssEncMode                    | String |          allow          | Controls the preference for using GSSAPI encryption for the connection, values are disable, allow, prefer, and require                                                                                                                                                                                                                        |
| useSpnego                     | String |          false           | Use SPNEGO in SSPI authentication requests                                                                                                                                                                                                                                                                                                   |
| adaptiveFetch                 | Boolean |          false          | Specifies if number of rows fetched in ResultSet by each fetch iteration should be dynamic. Number of rows will be calculated by dividing maxResultBuffer size into max row size observed so far. Requires declaring maxResultBuffer and defaultRowFetchSize for first iteration.                                                            |
| adaptiveFetchMinimum          | Integer |            0            | Specifies minimum number of rows, which can be calculated by adaptiveFetch. Number of rows used by adaptiveFetch cannot go below this value.                                                                                                                                                                                                 |
| adaptiveFetchMaximum          | Integer |           -1            | Specifies maximum number of rows, which can be calculated by adaptiveFetch. Number of rows used by adaptiveFetch cannot go above this value. Any negative number set as adaptiveFetchMaximum is used by adaptiveFetch as infinity number of rows.                                                                                            |
| localSocketAddress            | String |          null           | Hostname or IP address given to explicitly configure the interface that the driver will bind the client side of the TCP/IP connection to when connecting.                                                                                                                                                                                     |
| quoteReturningIdentifiers     | Boolean |          true           | By default we double quote returning identifiers. Some ORM's already quote them. Switch allows them to turn this off                                                                                                                                                                                                                         |
| requireAuth                   | String |          null           | Comma-separated list of acceptable authentication methods. Use '!' prefix to reject methods (e.g., '!password' to reject cleartext). Supported: password, md5, gss, sspi, scram-sha-256, none. Cannot mix positive and negative options.                                                                                                    |
| authenticationPluginClassName | String |          null           | Fully qualified class name of the class implementing the AuthenticationPlugin interface. If this is null, the password value in the connection properties will be used.                                                                                                                                                                       |
| unknownLength                 | Integer |   Integer.MAX_LENGTH    | Specifies the length to return for types of unknown length                                                                                                                                                                                                                                                                                   |
| stringtype                    | String |          null           | Specify the type to use when binding `PreparedStatement` parameters set via `setString()`                                                                                                                                                                                                                                                     |
| channelBinding                 | String |   prefer    | This option controls the client's use of channel binding. `require` means that the connection must employ channel binding, `prefer` means that the client will choose channel binding if available, and `disable` prevents the use of channel binding.                                                                                                   |

## Use the Driver

- Passing new connection properties for load balancing in connection url or properties bag

  For uniform load balancing across all the servers you just need to specify the _load-balance_ property in the url:
    ```
    String yburl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte?user=yugabyte&password=yugabyte&load-balance=any";
    DriverManager.getConnection(yburl);
    ```

  For specifying topology keys you need to set the additional property with a valid comma separated value:
    ```
    String yburl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte?user=yugabyte&password=yugabyte&load-balance=true&topology-keys=cloud1.region1.zone1,cloud1.region1.zone2";
    DriverManager.getConnection(yburl);
    ```

  If you have a read-replica cluster in your universe and want to connect your app strictly to the read-replica nodes in the universe (for example, because its a read-only app and you don't want to affect primary nodes which are servicing write-workloads):
    ```
    String yburl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte?user=yugabyte&password=yugabyte&load-balance=only-rr";
    DriverManager.getConnection(yburl);
    ```
  If no read-replica nodes are available above, the driver will attempt to connect to the endpoint(s) given in the url; `127.0.0.1` in this case.

### Specifying fallback zones

  For topology-aware load balancing, you can now specify fallback placements too. This is not applicable for cluster-aware load balancing.
  Each placement value can be suffixed with a colon (`:`) followed by a preference value between 1 and 10.
  A preference value of `:1` means it is a primary placement. A preference value of `:2` means it is the first fallback placement and so on.
  If no preference value is provided, it is considered to be a primary placement (equivalent to one with preference value `:1`). Example given below.

```
String yburl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte?user=yugabyte&password=yugabyte&load-balance=true&topology-keys=cloud1.region1.zone1:1,cloud1.region1.zone2:2";

```

  You can also use `*` for specifying all the zones in a given region as shown below. This is not allowed for cloud or region values.

```
String yburl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte?user=yugabyte&password=yugabyte&load-balance=true&topology-keys=cloud1.region1.*:1,cloud1.region2.*:2";
```

  The driver attempts connection to servers in the first fallback placement(s) if it does not find any servers available in the primary placement(s). If no servers are available in the first fallback placement(s),
  then it attempts to connect to servers in the second fallback placement(s), if specified. This continues until the driver finds a server to connect to, else an error is returned to the application.
  And this repeats for each connection request.

- Create and setup the DataSource for uniform load balancing
  A datasource for Yugabyte has been added. It can be configured like this for load balancing behaviour.
    ```
    String jdbcUrl = "jdbc:yugabytedb://127.0.0.1:5433/yugabyte";
    YBClusterAwareDataSource ds = new YBClusterAwareDataSource();
    ds.setUrl(jdbcUrl);
    // If topology aware distribution to be enabled then
    ds.setTopologyKeys("cloud1.region1.zone1,cloud1.region2.zone2");
    // If you want to provide more endpoints to safeguard against even first connection failure
    // due to the possible unavailability of initial contact point:
    ds.setAdditionalEndpoints("127.0.0.2:5433,127.0.0.3:5433");

    Connection conn = ds.getConnection();
    ```

- Create and setup the DataSource with a popular pooling solution like Hikari

    ```
    Properties poolProperties = new Properties();
    poolProperties.setProperty("dataSourceClassName", "com.yugabyte.ysql.YBClusterAwareDataSource");
    poolProperties.setProperty("maximumPoolSize", 10);
    poolProperties.setProperty("dataSource.serverName", "127.0.0.1");
    poolProperties.setProperty("dataSource.portNumber", "5433");
    poolProperties.setProperty("dataSource.databaseName", "yugabyte");
    poolProperties.setProperty("dataSource.user", "yugabyte");
    poolProperties.setProperty("dataSource.password", "yugabyte");
    // If you want to provide additional end points
    String additionalEndpoints = "127.0.0.2:5433,127.0.0.3:5433,127.0.0.4:5433,127.0.0.5:5433";
    poolProperties.setProperty("dataSource.additionalEndpoints", additionalEndpoints);
    // If you want to load balance between specific geo locations using topology keys
    String geoLocations = "cloud1.region1.zone1,cloud1.region2.zone2";
    poolProperties.setProperty("dataSource.topologyKeys", geoLocations);

    poolProperties.setProperty("poolName", name);

    HikariConfig config = new HikariConfig(poolProperties);
    config.validate();
    HikariDataSource ds = new HikariDataSource(config);

    Connection conn = ds.getConnection();
    ```

    Note that the property `dataSource.additionalEndpoints`, if specified, should include the respective port numbers as
    shown above, specially if those are not the default port numbers (`5433`).

    Otherwise, when the driver needs to connect to any of these additional endpoints (when the primary endpoint
    specified via `serverName` is unavailable), it will use the default port number (`5433`) and not
    `dataSource.portNumber` to connect to them.

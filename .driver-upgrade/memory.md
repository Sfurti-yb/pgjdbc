# What we know about yugabyte/pgjdbc

Written by earlier upgrade sessions. Every line cost a run to discover.

Treat it as a starting point, not as fact: the tree may have moved since. If
something here is wrong, correct it -- that is worth more than the upgrade
itself, because the next session inherits whatever you leave.

Add what you learn under "Learned this run". Anything above it is already
stored; only new lines are kept.

## Learned this run

- Rebase REL42.7.3 -> REL42.7.13: First commit (fork-point) had 54 commits to replay
- Upstream deleted test-anorm-sbt/ and test-gss/ modules entirely - accept deletions
- Upstream deleted benchmarks/src/jmh/java/org/postgresql/util/ConnectionUtil.java - functionality moved to TestUtil
- build.properties: upstream renamed `server/port/database` to `test.url.PGHOST/PGPORT/PGDBNAME`
- JDBC URL scheme: Always use `jdbc:yugabytedb://` instead of `jdbc:postgresql://`
- YugabyteDB-specific features that must survive: ClusterAwareLoadBalancer, TopologyAwareLoadBalancer, YBClusterAwareDataSource, LoadBalanceProperties
- Version bumps (e.g., "Bump the version to X-yb-N") should not be replayed - version set at end
- Group ID: Always `com.yugabyte`, Artifact ID: `jdbc-yugabytedb`
- When upstream refactored to StringBuilder in PgDatabaseMetaData, adapt our hint additions to use StringBuilder too

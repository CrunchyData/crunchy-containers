/**
 * Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

/**
 * pgbouncer-uninstall.sql removes the general infrastructure for using pgBouncer
 * with the PostgreSQL Operator
 *
 * This has to be executed in every database that had pgbouncer made available
 * to as well as template1
 */

/**
 * Remove the SECURITY DEFINER function that returns non-privileged and
 * non-system user credentials
 */
DROP FUNCTION IF EXISTS pgbouncer.get_auth(username TEXT);

/**
 * Drop the "pgbouncer" schema, and if anything exists in it, ensure it is
 * wiped out. Woe to those who used a system schema to store their own things...
 */
DROP SCHEMA IF EXISTS pgbouncer CASCADE;

/**
 * Drop anything owned by the pgbouncer user. It should be nothing at this
 * point, but better safe than sorry...
 */
DROP OWNED BY pgbouncer CASCADE;

/**
 * So, we can't drop the pgbouncer role as this file runs on an individual
 * database. We need **all** objects associated "pgbouncer" dropped before we
 * can execute `DROP ROLE pgbouncer;`
 */

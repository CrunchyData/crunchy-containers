#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generate PDFs -

a2x -f pdf ./examples.adoc
a2x -f pdf ./dedicated.adoc
a2x -f pdf ./install.adoc
a2x -f pdf ./containers.adoc
a2x -f pdf ./sshd.adoc
a2x -f pdf ./errata.adoc
a2x -f pdf ./backrest.adoc

# Generate XHTML files into the ./xhtml/ directory -

#a2x -f xhtml ./examples.adoc -D ./xhtml/
#a2x -f xhtml ./dedicated.adoc -D ./xhtml/
#a2x -f xhtml ./install.adoc -D ./xhtml/
#a2x -f xhtml ./containers.adoc -D ./xhtml/

# Generate manpages -

a2x -f manpage ./atomic/backup/help.md
a2x -f manpage ./atomic/collect/help.md
a2x -f manpage ./atomic/dba/help.md
a2x -f manpage ./atomic/grafana/help.md
a2x -f manpage ./atomic/pgadmin4/help.md
a2x -f manpage ./atomic/pgbadger/help.md
a2x -f manpage ./atomic/pgbouncer/help.md
a2x -f manpage ./atomic/pgpool/help.md
a2x -f manpage ./atomic/postgres-gis/help.md
a2x -f manpage ./atomic/postgres/help.md
a2x -f manpage ./atomic/prometheus/help.md
a2x -f manpage ./atomic/upgrade/help.md
a2x -f manpage ./atomic/vacuum/help.md
a2x -f manpage ./atomic/watch/help.md
a2x -f manpage ./atomic/backrestrestore/help.md

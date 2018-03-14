#!/bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
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
a2x -f pdf ./pitr.adoc

# Generate XHTML files into the ./xhtml/ directory -

#a2x -f xhtml ./examples.adoc -D ./xhtml/
#a2x -f xhtml ./dedicated.adoc -D ./xhtml/
#a2x -f xhtml ./install.adoc -D ./xhtml/
#a2x -f xhtml ./containers.adoc -D ./xhtml/
#a2x -f xhtml ./pitr.adoc -D ./xhtml/

# Generate manpages -

a2x -f manpage ./backup/help.md
a2x -f manpage ./collect/help.md
a2x -f manpage ./dba/help.md
a2x -f manpage ./grafana/help.md
a2x -f manpage ./pgadmin4/help.md
a2x -f manpage ./pgbadger/help.md
a2x -f manpage ./pgbouncer/help.md
a2x -f manpage ./pgpool/help.md
a2x -f manpage ./postgres-gis/help.md
a2x -f manpage ./postgres/help.md
a2x -f manpage ./prometheus/help.md
a2x -f manpage ./upgrade/help.md
a2x -f manpage ./vacuum/help.md
a2x -f manpage ./watch/help.md
a2x -f manpage ./backrestrestore/help.md

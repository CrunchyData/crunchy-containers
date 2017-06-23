#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
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


asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/examples.html \
-a toc2 \
-a footer \
-a toc-placement=right \
./examples.adoc

asciidoctor-pdf ./examples.adoc --out-file ./pdf/examples.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/dedicated.html \
-a toc2 \
-a toc-placement=right \
./dedicated.adoc

asciidoctor-pdf ./dedicated.adoc --out-file ./pdf/dedicated.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/install.html \
-a toc2 \
-a toc-placement=right \
./install.adoc

asciidoctor-pdf ./install.adoc --out-file ./pdf/install.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/metrics.html \
-a toc2 \
-a toc-placement=right \
./metrics.adoc

asciidoctor-pdf ./metrics.adoc --out-file ./pdf/metrics.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/containers.html \
-a toc2 \
-a toc-placement=right \
./containers.adoc

asciidoctor-pdf ./containers.adoc --out-file ./pdf/containers.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/pitr.html \
-a toc2 \
-a toc-placement=right \
./pitr.adoc

asciidoctor-pdf ./pitr.adoc --out-file ./pdf/pitr.pdf

# this utility is used for redhat container atomic help files
go get github.com/cpuguy83/go-md2man

go-md2man -in ./backup/help.md -out ./backup/help.1
go-md2man -in ./collect/help.md -out ./collect/help.1
go-md2man -in ./dba/help.md -out ./dba/help.1
go-md2man -in ./grafana/help.md -out ./grafana/help.1
go-md2man -in ./pgadmin4/help.md -out ./pgadmin4/help.1
go-md2man -in ./pgbadger/help.md -out ./pgbadger/help.1
go-md2man -in ./pgbouncer/help.md -out ./pgbouncer/help.1
go-md2man -in ./pgpool/help.md -out ./pgpool/help.1
go-md2man -in ./postgres-gis/help.md -out ./postgres-gis/help.1
go-md2man -in ./postgres/help.md -out ./postgres/help.1
go-md2man -in ./prometheus/help.md -out ./prometheus/help.1
go-md2man -in ./promgateway/help.md -out ./promgateway/help.1
go-md2man -in ./upgrade/help.md -out ./upgrade/help.1
go-md2man -in ./vacuum/help.md -out ./vacuum/help.1
go-md2man -in ./watch/help.md -out ./watch/help.1
go-md2man -in ./backrestrestore/help.md -out ./backrestrestore/help.1


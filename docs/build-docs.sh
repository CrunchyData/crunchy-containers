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

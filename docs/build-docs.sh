#!/bin/bash

# Copyright 2016 Crunchy Data Solutions, Inc.
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
-o ./htmldoc/standalone.html \
-a toc2 \
-a footer \
-a toc-placement=right \
./standalone.asciidoc

asciidoctor-pdf ./standalone.asciidoc --out-file ./pdf/standalone.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/openshift.html \
-a toc2 \
-a toc-placement=right \
./openshift.asciidoc

asciidoctor-pdf ./openshift.asciidoc --out-file ./pdf/openshift.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/install.html \
-a toc2 \
-a toc-placement=right \
./install.asciidoc

asciidoctor-pdf ./install.asciidoc --out-file ./pdf/install.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/metrics.html \
-a toc2 \
-a toc-placement=right \
./metrics.asciidoc

asciidoctor-pdf ./metrics.asciidoc --out-file ./pdf/metrics.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/containers.html \
-a toc2 \
-a toc-placement=right \
./containers.asciidoc

asciidoctor-pdf ./containers.asciidoc --out-file ./pdf/containers.pdf

asciidoc \
-b bootstrap \
-f ./demo.conf \
-o ./htmldoc/kube.html \
-a toc2 \
-a toc-placement=right \
./kube.asciidoc

asciidoctor-pdf ./kube.asciidoc --out-file ./pdf/kube.pdf

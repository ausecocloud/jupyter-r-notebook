# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY:	build push pull

PREFIX = hub.bccvl.org.au/jupyter
IMAGE = r-notebook
TAG ?= latest

dev:
	docker run --rm -it -v $(PWD)/jupyter-rsession-proxy:/code/jupyter-rsession-proxy -v $(PWD)/jupyter-server-proxy:/code/jupyter-server-proxy -p 8888:8888 -e "DROPBOX_APPKEY=$(DROPBOX_APPKEY)" $(PREFIX)/$(IMAGE):$(TAG) bash

test:
	docker run --rm -it -p 8888:8888 -e "DROPBOX_APPKEY=$(DROPBOX_APPKEY)" $(PREFIX)/$(IMAGE):$(TAG) bash

build:
	docker build -t $(PREFIX)/$(IMAGE):$(TAG) .

push:
	docker push $(PREFIX)/$(IMAGE):$(TAG)

pull:
	docker pull $(PREFIX)/$(IMAGE):$(TAG)

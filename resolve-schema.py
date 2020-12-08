#!/usr/bin/env python3

# Copyright 2020 British Broadcasting Corporation
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

# This file is sourced from build scripts
# It now pulls in settings from _config.yml

import getopt, sys, os
import jsonref
from pathlib import Path
import json

# This is from TestHelper.py in nmos-testing

def load_resolved_schema(spec_path, file_name=None, schema_obj=None, path_prefix=True):
    """
    Parses JSON as well as resolves any `$ref`s, including references to
    local files and remote (HTTP/S) files.
    """

    # Only one of file_name or schema_obj must be set
    assert bool(file_name) != bool(schema_obj)

    if path_prefix:
        spec_path = os.path.join(spec_path, "APIs/schemas/")
    base_path = os.path.abspath(spec_path)
    if not base_path.endswith("/"):
        base_path = base_path + "/"
    if os.name == "nt":
        base_uri_path = "file:///" + base_path.replace('\\', '/')
    else:
        base_uri_path = "file://" + base_path

    loader = jsonref.JsonLoader(cache_results=False)

    if file_name:
        json_file = str(Path(base_path) / file_name)
        with open(json_file, "r") as f:
            schema = jsonref.load(f, base_uri=base_uri_path, loader=loader, jsonschema=True)
    elif schema_obj:
        # Work around an exception when there's nothing to resolve using an object
        if "$ref" in schema_obj:
            schema = jsonref.JsonRef.replace_refs(schema_obj, base_uri=base_uri_path, loader=loader, jsonschema=True)
        else:
            schema = schema_obj

    return schema


def main():
    if len(sys.argv) != 2:
        print("Wrong number of arguments")
        sys.exit(2)

    print(json.dumps(load_resolved_schema(".", sys.argv[1], path_prefix=False), indent=4, sort_keys=True))

if __name__ == "__main__":
    main()

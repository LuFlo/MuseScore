#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# MuseScore-CLA-applies
#
# MuseScore
# Music Composition & Notation
#
# Copyright (C) 2021 MuseScore BVBA and others
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

S3_KEY=""
S3_SECRET=""
S3_URL="s3://convertor.musescore.org"
ARTIFACTS_DIR=build.artifacts
ARTIFACT_PATH=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --s3_key) S3_KEY="$2"; shift ;;
        --s3_secret) S3_SECRET="$2"; shift ;;
        --artifact) ARTIFACT_PATH="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$S3_KEY" ]; then echo "error: not set S3_KEY"; exit 1; fi
if [ -z "$S3_SECRET" ]; then echo "error: not set S3_SECRET"; exit 1; fi

if [ -z "$ARTIFACT_PATH" ]; then 
    ARTIFACT_NAME=$(cat $ARTIFACTS_DIR/env/artifact_name.env)
    ARTIFACT_PATH=$ARTIFACTS_DIR/$ARTIFACT_NAME
fi

ARTIFACT_NAME=$(basename $ARTIFACT_PATH)

command -v s3cmd >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "=== Install tools ==="

    apt install python3-setuptools

    echo "Install s3cmd"
    pip3 install s3cmd
fi

cat >~/.s3cfg <<EOL
[default]
access_key = ${S3_KEY}
bucket_location = US
cloudfront_host = cloudfront.amazonaws.com
cloudfront_resource = /2010-07-15/distribution
default_mime_type = binary/octet-stream
delete_removed = False
dry_run = False
encoding = UTF-8
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = None
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase =
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
list_md5 = False
log_target_prefix =
preserve_attrs = True
progress_meter = True
proxy_host =
proxy_port = 0
recursive = False
recv_chunk = 4096
reduced_redundancy = False
secret_key = ${S3_SECRET}
send_chunk = 4096
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
urlencoding_mode = normal
use_https = False
verbosity = WARNING
EOL

echo "s3cmd version: $(s3cmd --version)"

echo "=== Publish to S3 ==="

s3cmd put --acl-public --guess-mime-type "$ARTIFACT_PATH" "$S3_URL/$ARTIFACT_NAME"
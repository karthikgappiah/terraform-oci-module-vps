#!/bin/bash

set -euo pipefail

# Package Upgrade
set +e
dnf -y upgrade
set -e

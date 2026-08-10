#!/bin/bash
#
# SPDX-FileCopyrightText: Majaahh
# SPDX-License-Identifier: Apache-2.0
#

# [
CONF=""
# ]

if [[ ! "$1" ]]; then
    echo "Usage: regen_noctalia_config.sh <out>"
    exit 1
fi

if [[ -f "$1" ]]; then
    rm -f "$1" || exit 1
fi

CONF="$(noctalia config export | perl -0pe 's/^\[lockscreen_widgets\].*?(?=^\[|\z)//ms')"

if [[ ! "$CONF" ]]; then
    echo "Failed to generate configuration"
    exit 1
fi

{
    echo "#"
    echo "# SPDX-FileCopyrightText: Majaahh"
    echo "# SPDX-License-Identifier: Apache-2.0"
    echo "#"
    echo ""
    echo "$CONF"
} > "$1"

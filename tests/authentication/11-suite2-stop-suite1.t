#!/bin/bash
# THIS FILE IS PART OF THE CYLC SUITE ENGINE.
# Copyright (C) 2008-2017 NIWA
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------
# Test calling "cylc shutdown suite1" from suite2.
# See https://github.com/cylc/cylc/issues/1843
. "$(dirname "$0")/test_header"

set_test_number 1

RUND="$(cylc get-global-config --print-run-dir)"
NAME1="cylctb-${CYLC_TEST_TIME_INIT}/${TEST_SOURCE_DIR_BASE}/${TEST_NAME_BASE}-1"
NAME2="cylctb-${CYLC_TEST_TIME_INIT}/${TEST_SOURCE_DIR_BASE}/${TEST_NAME_BASE}-2"
SUITE1_RUND="${RUND}/${NAME1}"
SUITE2_RUND="${RUND}/${NAME2}"
cylc register "${NAME1}"
cp -p "${TEST_SOURCE_DIR}/basic/suite.rc" "${SUITE1_RUND}"
cylc register "${NAME2}"
cat >"${SUITE2_RUND}/suite.rc" <<__SUITERC__
[cylc]
    abort if any task fails=True
[scheduling]
    [[dependencies]]
        graph=t1
[runtime]
    [[t1]]
        script=cylc shutdown "${NAME1}"
__SUITERC__
cylc run --no-detach "${NAME1}" 1>'1.out' 2>&1 &
poll '!' test -e "${SUITE1_RUND}/.service/contact"
run_ok "${TEST_NAME_BASE}" cylc run --no-detach "${NAME2}"
cylc shutdown "${NAME1}" --max-polls=20 --interval=1 1>'/dev/null' 2>&1 || true
purge_suite "${NAME1}"
purge_suite "${NAME2}"
exit

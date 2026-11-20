# SPDX-License-Identifier: GPL-2.0
# Unit tests that need neither root nor a network namespace.
CFLAGS=
LDLIBS=
include ../../config.mk

.PHONY: check version rt_names_conf

check: version rt_names_conf

version: ../../ip/ip ../../tc/tc
	../../ip/ip -V
	../../tc/tc -V

rt_names_conf: rt_names_conf.c ../../lib/libutil.a ../../lib/libnetlink.a
	CC="$(CC)" CFLAGS="$(CFLAGS)" LDLIBS="$(LDLIBS)" $(SHELL) ./rt_names_conf.sh ../..

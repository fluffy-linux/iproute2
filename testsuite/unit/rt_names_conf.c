// SPDX-License-Identifier: GPL-2.0
/*
 * Print iproute2 name lookups, one per line, so that rt_names_conf.sh can
 * check which configuration files lib/rt_names.c and tc/tc_util.c read.
 * The test compiles this together with lib/rt_names.c and tc/tc_util.c,
 * pointing CONF_VENDOR_DIR, CONF_USR_DIR and CONF_ETC_DIR at a fixture.
 *
 * Arguments:
 *   table:ID    rtnl_rttable_n2a(ID)
 *   proto:ID    rtnl_rtprot_n2a(ID)
 *   classid:H   cls_names_init(NULL), then sprint_tc_classid(H), in hex
 */
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"
#include "rt_names.h"
#include "names.h"
#include "tc_util.h"

bool use_names = true;

int main(int argc, char **argv)
{
	char buf[64];
	int i;

	for (i = 1; i < argc; i++) {
		const char *arg = argv[i];

		if (strncmp(arg, "table:", 6) == 0) {
			puts(rtnl_rttable_n2a(atoi(arg + 6), buf, sizeof(buf)));
		} else if (strncmp(arg, "proto:", 6) == 0) {
			puts(rtnl_rtprot_n2a(atoi(arg + 6), buf, sizeof(buf)));
		} else if (strncmp(arg, "classid:", 8) == 0) {
			int ret = cls_names_init(NULL);

			if (ret) {
				printf("cls_names_init=%d\n", ret);
				continue;
			}
			sprint_tc_classid(strtoul(arg + 8, NULL, 16), buf);
			puts(buf);
			cls_names_uninit();
		} else {
			fprintf(stderr, "unknown lookup %s\n", arg);
			return 2;
		}
	}
	return 0;
}

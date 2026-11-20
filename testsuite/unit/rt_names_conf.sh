#! /bin/sh
# Test where lib/rt_names.c and tc/tc_util.c look for configuration:
# every directory the CONF_VENDOR_DIR wildcard matches, then CONF_USR_DIR,
# then CONF_ETC_DIR, later files overriding earlier ones; rt_tables.d
# drop-ins from vendor directories, masked by a CONF_ETC_DIR drop-in of
# the same name.  All three directories live under a temporary fixture.
#
# Usage: CC=cc CFLAGS=... LDLIBS=... $(SHELL) rt_names_conf.sh TOP

top=${1:?usage: $0 TOP}
case $top in /*) ;; *) top=$(pwd)/$top ;; esac
here=$(cd "$(dirname "$0")" && pwd) || exit 99
: "${CC:=cc}"
td="$(mktemp -d)" || exit 99
trap 'rm -rf "$td"' EXIT
fail=0

vendor="$td/sw/iproute2/etc/iproute2"
pkgb="$td/sw/pkgB/etc/iproute2"
usr="$td/usr/etc/iproute2"
etc="$td/etc/iproute2"
mkdir -p "$vendor" "$pkgb/rt_tables.d" "$usr" || exit 99
cp -R "$top/etc/iproute2/." "$vendor/" || exit 99
printf '42\tfluffy_vendor\n' >> "$vendor/rt_tables"
printf '43\tfluffy_dropin\n' > "$pkgb/rt_tables.d/extra.conf"
printf '1:10\tfluffy_root\n' > "$pkgb/tc_cls"
printf '44\tfluffy_usr\n' > "$usr/rt_tables"

if ! $CC -D_GNU_SOURCE $CFLAGS \
    -I"$top/include" -I"$top/include/uapi" -I"$top/tc" \
    -DCONF_VENDOR_DIR="\"$td/sw/*/etc/iproute2\"" \
    -DCONF_USR_DIR="\"$usr\"" \
    -DCONF_ETC_DIR="\"$etc\"" \
    "$here/rt_names_conf.c" "$top/lib/rt_names.c" "$top/tc/tc_util.c" \
    "$top/lib/libutil.a" "$top/lib/libnetlink.a" -lm $LDLIBS \
    -o "$td/rt_names_conf"
then
    echo "FAIL: building rt_names_conf"
    exit 1
fi

expect() {
    got=$("$td/rt_names_conf" "$2" 2>&1)
    if test "$got" = "$1"
    then
        echo "PASS: $stage: $2 -> $got"
    else
        echo "FAIL: $stage: $2: got '$got', want '$1'"
        fail=1
    fi
}

stage="vendor+usr"
expect local table:255
expect fluffy_vendor table:42
expect fluffy_dropin table:43
expect fluffy_usr table:44
expect kernel proto:2
expect 'fluffy_root#1:10' classid:10010

stage="etc override"
mkdir -p "$etc" || exit 99
printf '42\tfluffy_etc\n' > "$etc/rt_tables"
printf '1:10\tfluffy_etc_cls\n' > "$etc/tc_cls"
expect fluffy_etc table:42
expect local table:255
expect fluffy_dropin table:43
expect fluffy_usr table:44
expect 'fluffy_etc_cls#1:10' classid:10010

stage="etc drop-in mask"
mkdir -p "$etc/rt_tables.d" || exit 99
printf '45\tfluffy_etc_dropin\n' > "$etc/rt_tables.d/extra.conf"
expect fluffy_etc_dropin table:45
expect 43 table:43

exit $fail

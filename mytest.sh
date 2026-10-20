#!/usr/bin/env bash
# Test only the functions that exist in ../libft (no Makefile needed).
# Usage: ./mytest.sh            -> test every ft_*.c found in ../libft
#        ./mytest.sh strlen memset   -> test only these
#        VALGRIND=1 ./mytest.sh -> also run under valgrind

cd "$(dirname "$0")" || exit 1
LIBFT="${LIBFT:-../libft}"
BUILD=".mybuild"
CC_C="${CC_C:-cc}"
CC_CPP="${CC_CPP:-$(command -v clang++ > /dev/null && echo clang++ || echo g++)}"
UTILS="utils/sigsegv.cpp utils/color.cpp utils/check.cpp myutils/leaks.cpp"  # fixed leaks hook for new glibc

R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; N=$'\e[0m'

rm -rf "$BUILD" && mkdir -p "$BUILD"

# 1) compile each of your .c files on its own, so one broken file doesn't block the others
echo "${B}[Compiling your files]${N}"
objs=()
for src in "$LIBFT"/ft_*.c; do
	[ -e "$src" ] || continue
	name=$(basename "$src" .c)
	if "$CC_C" -Wall -Wextra -Werror -c "$src" -I"$LIBFT" -o "$BUILD/$name.o" 2> "$BUILD/$name.err"; then
		objs+=("$BUILD/$name.o")
	else
		echo "${R}  compile error: $name.c${N}"
		sed 's/^/    /' "$BUILD/$name.err"
	fi
done
[ ${#objs[@]} -gt 0 ] && ar rcs "$BUILD/libft.a" "${objs[@]}"

# 2) pick which tests to run
if [ $# -gt 0 ]; then
	funcs=("$@")
else
	funcs=()
	for src in "$LIBFT"/ft_*.c; do
		[ -e "$src" ] || continue
		n=$(basename "$src" .c); funcs+=("${n#ft_}")
	done
fi

# 3) build + run each test
echo "${B}[Tests]${N}"
for f in "${funcs[@]}"; do
	f="${f#ft_}"
	test="tests/ft_${f}_test.cpp"
	if [ ! -f "$test" ]; then
		echo "${Y}ft_$f: no test available${N}"; continue
	fi
	if [ ! -f "$BUILD/ft_$f.o" ]; then
		echo "${R}ft_$f: skipped (missing or did not compile)${N}"; continue
	fi
	if ! "$CC_CPP" -g3 -std=c++11 -Iutils -I"$LIBFT" $UTILS "$test" \
		-L"$BUILD" -lft -ldl -o "$BUILD/t_$f" 2> "$BUILD/t_$f.err"; then
		echo "${R}ft_$f: test failed to build/link:${N}"
		sed 's/^/    /' "$BUILD/t_$f.err" | head -20
		continue
	fi
	if [ -n "$VALGRIND" ] && command -v valgrind > /dev/null; then
		valgrind -q --leak-check=full "$BUILD/t_$f"
	else
		"$BUILD/t_$f"
	fi
done

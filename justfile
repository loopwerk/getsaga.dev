run:
	#!/usr/bin/env bash
	set -m
	pnpm css-watch &
	CSS_PID=$!
	trap "kill $CSS_PID 2>/dev/null" EXIT
	browser-sync -w

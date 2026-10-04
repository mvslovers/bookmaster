#!/usr/bin/env python3
"""Check the joints of syntax diagrams written for bookmaster's syntax().

Every vertical arm must meet a cell that takes it: a box character with an
arm pointing back, or the loop arrow.  A lone ├ or ┤ with no vertical
neighbour is a fragment bracket and is drawn as a short tick, so it is not
an error.  «» mark a variable and take no column.

Exit status: 0 if every diagram joins up, 1 otherwise.
"""
import sys

UP = set("│└┘├┤┴┼")     # cells with an arm pointing up
DOWN = set("│┌┐├┤┬┼")   # cells with an arm pointing down


def cells(line):
    return line.replace("«", "").replace("»", "")


def check(path):
    rows = [cells(l) for l in open(path, encoding="utf-8").read().rstrip("\n").split("\n")]
    width = max(map(len, rows))
    rows = [r.ljust(width) for r in rows]

    def at(y, x):
        return rows[y][x] if 0 <= y < len(rows) else " "

    bad = 0
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            above, below = at(y - 1, x), at(y + 1, x)
            joins_up = above in DOWN or above == "▼"
            joins_down = below in UP or below == "▼"
            if c in "├┤" and not joins_up and not joins_down:
                continue                      # a fragment bracket
            if c in DOWN and not joins_down:
                print(f"{path}: row {y + 1} col {x + 1}: {c!r} has no joint below ({below!r})")
                bad += 1
            if c in UP and not joins_up:
                print(f"{path}: row {y + 1} col {x + 1}: {c!r} has no joint above ({above!r})")
                bad += 1
    return bad


if __name__ == "__main__":
    total = sum(check(p) for p in sys.argv[1:])
    print(f"{len(sys.argv) - 1} diagram(s), {total} problem(s)")
    sys.exit(1 if total else 0)

#!/usr/bin/env python3
"""Write a self-contained coverage badge as SVG.

No service and no network: shields.io renders the same shape from a hosted JSON endpoint, and Codecov
from an account, but a badge is a few hundred bytes of static SVG and we can commit it ourselves.

Usage:
    python3 Coverage/badge.py 97.24 > .github/badges/coverage.svg
"""

import argparse
import sys

# shields.io's own thresholds, so the color means the same thing a reader is used to.
COLORS = (
    (50, "#e05d44"),  # red
    (70, "#fe7d37"),  # orange
    (80, "#dfb317"),  # yellow
    (90, "#a4a61d"),  # olive
    (95, "#97CA00"),  # green
    (float("inf"), "#4c1"),  # bright green
)

# 11px in this font family averages a shade under 6.6px per character, plus 10px of padding a side.
CHARACTER_WIDTH = 6.6
PADDING = 10


def color(percentage):
    return next(hex for limit, hex in COLORS if percentage < limit)


def badge(label, value, percentage):
    label_width = int(len(label) * CHARACTER_WIDTH) + PADDING
    value_width = int(len(value) * CHARACTER_WIDTH) + PADDING
    width = label_width + value_width

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="20" role="img" aria-label="{label}: {value}">
  <title>{label}: {value}</title>
  <linearGradient id="shine" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="rounded">
    <rect width="{width}" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#rounded)">
    <rect width="{label_width}" height="20" fill="#555"/>
    <rect x="{label_width}" width="{value_width}" height="20" fill="{color(percentage)}"/>
    <rect width="{width}" height="20" fill="url(#shine)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
    <text x="{label_width / 2:.0f}" y="15" fill="#010101" fill-opacity=".3">{label}</text>
    <text x="{label_width / 2:.0f}" y="14">{label}</text>
    <text x="{label_width + value_width / 2:.0f}" y="15" fill="#010101" fill-opacity=".3">{value}</text>
    <text x="{label_width + value_width / 2:.0f}" y="14">{value}</text>
  </g>
</svg>
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("percentage", type=float, help="the coverage percentage, such as 97.24")
    parser.add_argument("--label", default="coverage")
    args = parser.parse_args()

    sys.stdout.write(badge(args.label, f"{args.percentage:.1f}%", args.percentage))


if __name__ == "__main__":
    sys.exit(main())

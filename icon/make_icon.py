#!/usr/bin/env python3
"""Draws the Git Puller app icon as an SVG, at macOS icon proportions."""

S = 1024
# macOS icons sit on a rounded square inset from the canvas edge.
M = S * 0.0977          # margin
BOX = S - 2 * M         # 832
R = BOX * 0.2237        # corner radius (squircle-ish)

cx = S / 2

# Branch geometry: a vertical trunk with a curve peeling off to the right,
# and a download arrow through the middle.
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#F97362"/>
      <stop offset="52%" stop-color="#F05133"/>
      <stop offset="100%" stop-color="#D2371A"/>
    </linearGradient>
    <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.26"/>
      <stop offset="46%" stop-color="#ffffff" stop-opacity="0.05"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <filter id="drop" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="{S*0.012:.1f}" stdDeviation="{S*0.016:.1f}"
                    flood-color="#000000" flood-opacity="0.28"/>
    </filter>
  </defs>

  <!-- rounded-square base -->
  <g filter="url(#drop)">
    <rect x="{M:.1f}" y="{M:.1f}" width="{BOX:.1f}" height="{BOX:.1f}" rx="{R:.1f}" fill="url(#bg)"/>
    <rect x="{M:.1f}" y="{M:.1f}" width="{BOX:.1f}" height="{BOX:.1f}" rx="{R:.1f}" fill="url(#sheen)"/>
    <rect x="{M+2:.1f}" y="{M+2:.1f}" width="{BOX-4:.1f}" height="{BOX-4:.1f}" rx="{R-2:.1f}"
          fill="none" stroke="#ffffff" stroke-opacity="0.30" stroke-width="3"/>
  </g>

  <!-- glyph -->
  <g stroke="#ffffff" stroke-width="46" stroke-linecap="round" fill="none">
    <!-- branch trunk, left -->
    <path d="M 372 330 L 372 694"/>
    <!-- branch peeling right into the arrow shaft -->
    <path d="M 372 470 C 372 585, 520 545, 604 545" stroke-opacity="0.92"/>
  </g>

  <!-- commit nodes on the trunk -->
  <g fill="#ffffff">
    <circle cx="372" cy="330" r="52"/>
    <circle cx="372" cy="694" r="52"/>
  </g>
  <g fill="url(#bg)">
    <circle cx="372" cy="330" r="24"/>
    <circle cx="372" cy="694" r="24"/>
  </g>

  <!-- pull arrow, pointing down -->
  <g stroke="#ffffff" stroke-width="46" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M 652 400 L 652 690"/>
    <path d="M 556 596 L 652 694 L 748 596"/>
  </g>
</svg>
'''

with open("icon.svg", "w") as f:
    f.write(svg)
print("icon.svg written")

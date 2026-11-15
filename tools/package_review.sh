#!/bin/sh
# Builds export/COMETO_review_<date>.zip: the whole project minus caches and git
# history, plus docs/ALL_SOURCE.txt. Run from the project root:
#     sh tools/package_review.sh
set -e
cd "$(dirname "$0")/.."
python3 tools/bundle_source.py
mkdir -p export
touch export/.gdignore
OUT="export/COMETO_review_$(date +%Y-%m-%d).zip"
rm -f "$OUT"
zip -r -q "$OUT" . -x ".git/*" ".godot/*" "export/*" "*.DS_Store" "*.tmp"
echo "$OUT  $(du -h "$OUT" | cut -f1)"

#!/usr/bin/bash
set -Eeuo pipefail

source /ctx/build_scripts/lib/common.sh
require_root
require_command python3
log_group "$(basename "$0")"

PRODUCT_JSON=/usr/share/codium/resources/app/product.json
[ -f "$PRODUCT_JSON" ] || { echo "missing: $PRODUCT_JSON" >&2; exit 1; }

# VSCodium ships an Open VSX gallery that is missing extensions we need.
# Replace only extensionsGallery; leave the rest of the RPM-owned file alone.
python3 - "$PRODUCT_JSON" <<'PY'
import json
import os
import re
import sys
import tempfile

product_path = sys.argv[1]

gallery = {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "commandUrl": "https://marketplace.visualstudio.com/items",
    "itemUrl": "https://marketplace.visualstudio.com/items",
    "assetsUrl": "https://vscdn.blob.core.windows.net/assets",
    "extensionUrl": "https://marketplace.visualstudio.com/vscode",
}

with open(product_path, encoding="utf-8") as f:
    original = f.read()

# Anchor on the indented closing line: URLs contain {publisher}/{name} braces.
pattern = r'(?ms)^([ \t]*)"extensionsGallery":[ \t]*\{.*?^\1\},?'
match = re.search(pattern, original)
if match is None:
    sys.exit("extensionsGallery block not found in " + product_path)

indent = match.group(1)
block = json.dumps(gallery, indent=2).replace("\n", "\n" + indent)
patched = (
    original[:match.start()]
    + indent + '"extensionsGallery": ' + block + ","
    + original[match.end():]
)

if json.loads(patched)["extensionsGallery"] != gallery:
    sys.exit("extensionsGallery patch did not apply")

fd, tmp = tempfile.mkstemp(prefix=".product.json-", dir=os.path.dirname(product_path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(patched)
    os.replace(tmp, product_path)
finally:
    if os.path.exists(tmp):
        os.unlink(tmp)
PY

chmod 0644 "$PRODUCT_JSON"
log_group_end

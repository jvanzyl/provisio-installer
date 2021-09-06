#!/usr/bin/env bash

profileBinDirectory=${3}

read -r -d '' vscodeScript <<'EOF'
#!/usr/bin/env bash
cd "${BASH_SOURCE%/*}"
open vscodium/VSCodium.app
EOF

echo "${vscodeScript}" > ${profileBinDirectory}/vscode
chmod +x ${profileBinDirectory}/vscode

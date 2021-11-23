#!/usr/bin/env bash

profileBinDirectory=${3}
version=${6}

read -r -d '' vscodeScript <<'EOF'
#!/usr/bin/env bash
cd "${BASH_SOURCE%/*}"
open vscodium/{version}/VSCodium.app
EOF

echo "${vscodeScript}" | sed -e "s/{version}/${version}/" > ${profileBinDirectory}/vscode
chmod +x ${profileBinDirectory}/vscode

{ url
  , dappPkgs ? (
    import (fetchTarball "https://github.com/makerdao/makerpkgs/tarball/master") {}
  ).dappPkgsVersions.master-20200216
}: with dappPkgs;

mkShell {
  DAPP_SOLC = solc-static-versions.solc_0_6_11 + "/bin/solc-0.6.11";
  buildInputs = [
    dapp
    hevm
    seth
    jq
    curl
  ];

  shellHook = ''
    export NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    unset SSL_CERT_FILE

    export ETH_RPC_URL="''${ETH_RPC_URL:-${url}}"
  '';
}

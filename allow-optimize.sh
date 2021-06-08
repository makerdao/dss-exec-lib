#!/usr/bin/env bash
set -e

#libFile="lib/dss/src/lib.sol"
#vatFile="lib/dss/src/vat.sol"
medFile="lib/median/src/median.sol"
osmMFile="lib/osm-mom/src/OsmMom.sol"
osmFile="lib/osm-mom/lib/osm/src/osm.sol"
#originalLibContent=$(cat "$libFile")
#originalVatContent=$(cat "$vatFile")
originalMedContent=$(cat "$medFile")
originalOsmContent=$(cat "$osmFile")
originalOsmMContent=$(cat "$osmMFile")

function clean() {
  #echo "$originalLibContent" > "$libFile"
  #echo "$originalVatContent" > "$vatFile"
  echo "$originalMedContent" > "$medFile"
  echo "$originalOsmContent" > "$osmFile"
  echo "$originalOsmMContent" > "$osmMFile"
}

trap clean EXIT

#content=$(sed '29,43 d' "$libFile")
#echo "$content" > "$libFile"

#content=$(sed '74,88 d' "$vatFile")
#echo "$content" > "$vatFile"

content=$(sed '31,45 d' "$medFile")
echo "$content" > "$medFile"

content=$(sed '33,47 d' "$osmFile")
echo "$content" > "$osmFile"

content=$(sed '39,53 d' "$osmMFile")
echo "$content" > "$osmMFile"

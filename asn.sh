#!/usr/bin/env bash

input="./asn.csv"
mkdir -p ./tmp ./data

while IFS= read -r line; do
  filename=$(echo ${line} | awk -F ',' '{print $1}')
  [[ "${line}" =~ ^# ]] && echo "skip: \"${line}\"" && continue
  IFS='|' read -r -a asns <<<$(echo ${line} | awk -F ',' '{print $2}')
  file="data/${filename}"

  echo "==================================="
  echo "Generating ${filename} CIDR list..."
  rm -rf ${file} && touch ${file}
  for asn in ${asns[@]}; do
    url="https://stat.ripe.net/data/ris-prefixes/data.json?list_prefixes=true&types=o&resource=${asn}"
    echo "-----------------------"
    echo "Fetching ${asn}..."
    curl -sSfL --retry 5 --retry-delay 2 --retry-all-errors ${url} -o ./tmp/${filename}-${asn}.txt \
      -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
    echo "::group::${asn}"
    cat "./tmp/${filename}-${asn}.txt"
    echo "::endgroup::"
    jq --raw-output '.data.prefixes.v4.originating[]' ./tmp/${filename}-${asn}.txt | sort -u >>${file}
    jq --raw-output '.data.prefixes.v6.originating[]' ./tmp/${filename}-${asn}.txt | sort -u >>${file}
  done
done <${input}

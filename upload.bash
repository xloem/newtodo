#!/usr/bin/env bash

LOCAL_MIRROR=.git/remote-mirror

url2txid() {
	echo "${1##*/}"
}

git init --bare "$LOCAL_MIRROR"
git -C "$LOCAL_MIRROR" config gc.auto 0
ARWEAVE_URL="$(git remote get-url arweave)"
ARWEAVE_TXID="$(url2txid "$ARWEAVE_URL")"
echo "$ARWEAVE_URL"/objects >> "$LOCAL_MIRROR"/objects/info/http-alternates
echo "../../$ARWEAVE_TXID"/objects >> "$LOCAL_MIRROR"/objects/info/alternates

git push --all --force "$LOCAL_MIRROR"
git -C "$LOCAL_MIRROR" update-server-info

HEAD=$(git rev-parse HEAD)

TAGS="$(
	echo -n "--tag-name HEAD --tag-value $HEAD "
	git rev-list --max-parents=0 HEAD | while read root_commit
	do
		echo -n "--tag-name commit-root --tag-value $root_commit "
	done
)"

HOME="$LOCAL_MIRROR" arkb deploy $TAGS --auto-confirm --use-bundler=https://node2.bundlr.network "$LOCAL_MIRROR" | tee arkb-log

ARWEAVE_URL="$(sed -ne 's!.*\(https://arweave.net/[-_=a-zA-Z0-9]*\).*!\1!p' arkb-log)"
ARWEAVE_TXID="$(url2txid "$ARWEAVE_URL")"

git remote set-url arweave "$ARWEAVE_URL"

mv "$LOCAL_MIRROR" "$LOCAL_MIRROR/../$ARWEAVE_TXID"

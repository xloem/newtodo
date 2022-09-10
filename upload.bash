#!/usr/bin/env bash

LOCAL_MIRROR=.git/remote-mirror

url2txid() {
	echo "${1##*/}"
}

git init --bare "$LOCAL_MIRROR"
ARWEAVE_URL="$(sed -ne 's!.*\(https://arweave.net/[-_=a-zA-Z0-9]*\).*!\1!p' arkb-log)"
ARWEAVE_TXID="$(url2txid "$ARWEAVE_URL")"
if [ -n "$ARWEAVE_TXID" ]
then
	LOCAL_ALTERNATE="$LOCAL_MIRROR"/../"$ARWEAVE_TXID"
	if [ ! -d "$LOCAL_ALTERNATE" ]
	then
		git -c http.followRedirects=true clone "$ARWEAVE_URL" "$LOCAL_ALTERNATE"
		mkdir -p "$LOCAL_ALTERNATE/objects"
	fi
		
	cp "$LOCAL_ALTERNATE"/objects/info/alternates "$LOCAL_MIRROR"/objects/info/alternates
	echo "../../$ARWEAVE_TXID"/objects >> "$LOCAL_MIRROR"/objects/info/alternates
	if (( $(stat -c %s "$LOCAL_MIRROR"/objects/info/alternates) > 100000 ))
	then
		echo "../../$ARWEAVE_TXID"/objects > "$LOCAL_MIRROR"/objects/info/alternates
	fi
fi

git push --all --force "$LOCAL_MIRROR"
git -C "$LOCAL_MIRROR" gc
git -C "$LOCAL_MIRROR" update-server-info

HEAD=$(git rev-parse HEAD)

TAGS="$(
	echo -n "--tag-name HEAD --tag-value $HEAD "
	git rev-list --max-parents=0 HEAD | while read root_commit
	do
		echo -n "--tag-name commit-root --tag-value $root_commit "
	done
)"

HOME="$LOCAL_MIRROR" arkb deploy $TAGS --no-colors --auto-confirm --use-bundler=https://node2.bundlr.network "$LOCAL_MIRROR" | tee arkb-log


ARWEAVE_URL="$(sed -ne 's!.*\(https://arweave.net/[-_=a-zA-Z0-9]*\).*!\1!p' arkb-log)"
ARWEAVE_TXID="$(url2txid "$ARWEAVE_URL")"

git add arkb-log
git commit -m "uploaded $ARWEAVE_TXID"

git remote set-url arweave "$ARWEAVE_URL"

mv "$LOCAL_MIRROR" "$LOCAL_MIRROR/../$ARWEAVE_TXID"

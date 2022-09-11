#!/usr/bin/env bash

git add phase1/*
git commit -m 'Files committed automatically by upload script'

LOCAL_MIRROR=.git/remote-mirror

url2txid() {
	echo "${1##*/}"
}

git init --bare "$LOCAL_MIRROR"
rm -rf "$LOCAL_MIRROR"/hooks/*
ARWEAVE_URL="$(sed -ne 's!.*\(https://arweave.net/[-_=a-zA-Z0-9]*\).*!\1!p' arkb-log)"
ARWEAVE_TXID="$(url2txid "$ARWEAVE_URL")"
if [ -n "$ARWEAVE_TXID" ]
then
	LOCAL_ALTERNATE="$LOCAL_MIRROR"/../"$ARWEAVE_TXID"
	if [ ! -d "$LOCAL_ALTERNATE" ]
	then
		git -c http.followRedirects=true clone --bare "$ARWEAVE_URL" "$LOCAL_ALTERNATE"
		mkdir -p "$LOCAL_ALTERNATE/objects"
	fi
		
	cp "$LOCAL_ALTERNATE"/objects/info/alternates "$LOCAL_MIRROR"/objects/info/alternates
	echo "../../$ARWEAVE_TXID"/objects >> "$LOCAL_MIRROR"/objects/info/alternates
	if (( $(stat -c %s "$LOCAL_MIRROR"/objects/info/alternates) > 100000 ))
	then
		LAST_PATH="../../$ARWEAVE_TXID/objects"
		echo "$LAST_PATH" > "$LOCAL_MIRROR"/objects/info/alternates
		while [ -s "$LOCAL_MIRROR"/objects/"$LAST_PATH"/info/alternates ] && ! (( $(stat -c %s "$LOCAL_MIRROR"/objects/info/alternates) > 100000 / 2))
		do
			LAST_PATH="$(head -n 1 "$LOCAL_MIRROR"/objects/"$LAST_PATH"/info/alternates)"
			echo "$LAST_PATH" >> "$LOCAL_MIRROR"/objects/info/alternates
		done
		while (( $(stat -c %s "$LOCAL_MIRROR"/objects/info/alternates) > 100000 / 2 ))
		do
			sed -i '$d' "$LOCAL_MIRROR"/objects/info/alternates
		done
		#sed -i '1!G;h;$!d' "$LOCAL_MIRROR"/objects/info/alternates
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

mv "$LOCAL_MIRROR" "$LOCAL_MIRROR/../$ARWEAVE_TXID"

git remote set-url arweave "$ARWEAVE_URL"
#git push --all github

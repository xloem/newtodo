#!/usr/bin/env bash
LOCAL_MIRROR=.git/remote-mirror
git init --bare "$LOCAL_MIRROR"
git -C "$LOCAL_MIRROR" config gc.auto 0

git push --force "$LOCAL_MIRROR"
git -C "$LOCAL_MIRROR" update-server-info

HOME="$LOCAL_MIRROR" arkb deploy --auto-confirm --use-bundler=https://node2.bundlr.network "$LOCAL_MIRROR" #| tee arkb-log

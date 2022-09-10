#!/usr/bin/env bash
git init --bare .git/remote-mirror
git -C .git/remote-mirror config gc.auto 0

git push remote-mirror
git -C .git/remote-mirror update-server-info

arkb deploy --use-bundler=https://node2.bundlr.network .git/remote-mirror | tee arkb-log

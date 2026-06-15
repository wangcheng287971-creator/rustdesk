#!/usr/bin/env bash
export CARGO_INCREMENTAL=0
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_LTO=fat
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter,hwcodec -j 4

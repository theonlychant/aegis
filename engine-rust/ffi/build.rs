use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    // engine-c is located at repo_root/engine-c relative to engine-rust/ffi
    let engine_c_src = manifest_dir.join("..").join("..").join("engine-c").join("src");
    let engine_c_include = manifest_dir.join("..").join("..").join("engine-c").join("include");

    let files = ["bridge.c", "wrapper.c", "test_bridge.c"];

    let mut build = cc::Build::new();
    build.include(engine_c_include);
    for f in &files {
        let p = engine_c_src.join(f);
        if p.exists() {
            build.file(p);
        }
    }
    // Allow cross-compilation via clang; allow position-independent code on macOS/iOS
    build.flag_if_supported("-fPIC");
    build.compile("aegis_engine_c");
}

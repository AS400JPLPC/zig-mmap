    ///-----------------------
    /// build Ptest
    ///-----------------------

const std = @import("std");


pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // library  libary motor
    // zig-src  source projet
    // src_c    source c/c++
    // zig-src/lib  source .h 



    // Building the executable
    
    const Prog = b.addExecutable(.{
    .name = "Ptest",
    .root_module = b.createModule(.{
        .root_source_file = b.path( "./Ptest.zig" ),
        .target = target,
        .optimize = optimize,
       }),
    });



    b.installArtifact(Prog);


}

///----------------------
/// build Test
///----------------------
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

    // for match use regex 
    //Prog.linkLibC();

    // Resolve the 'library' dependency.
    const library_dep = b.dependency("libtui", .{});

    // Import the smaller 'cursed' and 'utils' modules exported by the library. etc...
    Prog.root_module.addImport("callpgm", library_dep.module("callpgm"));

    Prog.root_module.addImport("crypt", library_dep.module("crypt"));
    Prog.root_module.addImport("zmmap", library_dep.module("zmmap"));
    

    b.installArtifact(Prog);


}

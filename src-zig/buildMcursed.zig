	///-----------------------
	/// prog calling
	/// zig 0.12.0 dev
	///-----------------------

const std = @import("std");


pub fn build(b: *std.Build) void {
	// Standard release options allow the person running `zig build` to select
	// between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
	const target   = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	// library			libary motor
	// zig-src			source projet
	// src_c			source c/c++
	// zig-src/lib		source .h 



	// Building the executable
	
	const Prog = b.addExecutable(.{
	.name = "Mcursed",
	.root_source_file = .{ .path = "./Mcursed.zig" },
	.target = target,
	.optimize = optimize,
	});

	// for match use regex 
	//Prog.linkLibC();

	// Resolve the 'library' dependency.
	const library_dep = b.dependency("library", .{});

	// Import the smaller 'cursed' and 'utils' modules exported by the library. etc...
	Prog.root_module.addImport("cursed", library_dep.module("cursed"));
	Prog.root_module.addImport("utils", library_dep.module("utils"));
    Prog.root_module.addImport("match", library_dep.module("match"));
    Prog.root_module.addImport("forms", library_dep.module("forms"));
    Prog.root_module.addImport("grid",  library_dep.module("grid"));
    Prog.root_module.addImport("menu", library_dep.module("menu"));
    Prog.root_module.addImport("callpgm", library_dep.module("callpgm"));

    Prog.root_module.addImport("crypto", library_dep.module("crypto"));
	Prog.root_module.addImport("zmmap", library_dep.module("zmmap"));

	b.installArtifact(Prog);


}

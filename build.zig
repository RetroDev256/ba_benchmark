const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ba_benchmark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const new = b.option(bool, "new", "whether to use the new allocator");
    exe.root_module.strip = b.option(bool, "strip", "remove debug info");
    exe.use_llvm = b.option(bool, "llvm", "use the llvm backend");
    exe.use_lld = b.option(bool, "lld", "use the lld linker");

    const options = b.addOptions();
    options.addOption(bool, "new", new orelse false);
    exe.root_module.addOptions("options", options);

    const bump_alloc = b.dependency("bump_alloc", .{});
    const BumpAllocator = bump_alloc.module("BumpAllocator");
    exe.root_module.addImport("BumpAllocator", BumpAllocator);

    b.installArtifact(exe);
}

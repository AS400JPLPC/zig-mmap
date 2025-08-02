const std = @import("std");
const print = std.debug.print;

const fs = std.fs;

const allocZmmap = std.heap.page_allocator;

var    ZPWR   :fs.File = undefined;
var    ZPWR_W   :fs.File = undefined;

const dirfile = "./qtemp";

var cDIR = std.fs.cwd();




pub fn unlock() void {
    // var out = ZPWR_W.writerStreaming(&.{});
    // out.interface.writeAll("N") catch unreachable;

    ZPWR.seekTo(0) catch unreachable;
    _=ZPWR.write("N") catch unreachable;
}



pub fn lock() void {
    // var out = ZPWR_W.writerStreaming(&.{});
    // out.interface.writeAll("Y") catch unreachable;

    ZPWR.seekTo(0) catch unreachable;
    _=ZPWR.write("Y") catch unreachable;
}

pub fn islock() bool {
    var buffer :[]u8 = allocZmmap.alloc( u8, 1024) catch unreachable;
    defer allocZmmap.free(buffer);
    _= ZPWR.read(buffer[0..]) catch unreachable;
    return std.mem.eql(u8, "Y", buffer[0..1]);
 }

pub fn main() !void {

    const timesStamp_ms: u64 = @bitCast(std.time.milliTimestamp());

    const parmTimes = std.fmt.allocPrint(allocZmmap,"{d}" ,.{timesStamp_ms})  catch unreachable;

    cDIR = std.fs.cwd().openDir(dirfile,.{}) catch unreachable;
   
const filePWR   = std.fmt.allocPrint(allocZmmap,"PWR{s}"   ,.{parmTimes})  catch unreachable;
    ZPWR =
    cDIR.createFile(filePWR , .{ .read = true, .truncate =true , .exclusive = false, .lock =.shared}) catch |e|
                @panic(std.fmt.allocPrint(allocZmmap,"err isFile Open CREAT FILEPWR .{any}\n", .{e})
                catch unreachable);

    ZPWR = cDIR.openFile(filePWR , .{.mode=.read_write , .lock =.shared}) catch |e| {
         @panic(std.fmt.allocPrint(allocZmmap,"\n{any} mmap fileLCI error open   {s}\n",.{e,filePWR })
            catch unreachable);
    };
    // ZPWR_W = cDIR.openFile(filePWR , .{.mode=.write_only , .lock =.shared}) catch |e| {
    //      @panic(std.fmt.allocPrint(allocZmmap,"\n{any} mmap fileLCI error open   {s}\n",.{e,filePWR })
    //         catch unreachable);
    // };


    var count : usize = 0;

while( count < 1000) {

     unlock();
     lock();
     _= islock();
     count += 1;
 }







}

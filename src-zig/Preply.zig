///-----------------------
/// prog echo
///-----------------------
const std = @import("std");

const map = @import("zmmap");


//============================================================================================
var out = std.fs.File.stdout().writerStreaming(&.{});
pub inline fn Print( comptime format: []const u8, args: anytype) void {
    out.interface.print(format, args) catch return;
 }
pub inline fn WriteAll( args: anytype) void {
    out.interface.writeAll(args) catch return;
 }
fn Pause() void{

    WriteAll("\nPause\r\n");
var stdin = std.fs.File.stdin();
    var buf: [16]u8 =  [_]u8{0} ** 16;
    var c  : usize = 0;
    while (c == 0) {
        c = stdin.read(&buf) catch unreachable;
    }
}
//============================================================================================
//-------------------------------
// datarea communication 
//-------------------------------
const COMUDS = struct { 
    // alpha numeric
    zua1 : [] const u8 ,
    zua2 : [] const u8 ,
    zua3 : [] const u8 ,
    zua4 : [] const u8 ,
    zua5 : [] const u8 ,

    // numérique
    zun1 : [] const u8 ,
    zun2 : [] const u8 ,
    zun3 : [] const u8 ,
    zun4 : [] const u8 ,
    zun5 : [] const u8 ,

    zu8  : u8,
    zcomit: bool,

};


fn initUDS() COMUDS {

    const vuds = COMUDS{
        .zua1 = "",
        .zua2 = "",
        .zua3 = "",
        .zua4 = "",
        .zua5 = "",
        
        .zun1 = "",
        .zun2 = "",
        .zun3 = "",
        .zun4 = "",
        .zun5 = "",
        .zu8 = 0,
        .zcomit = true
    };
    return vuds ;
}
const allocUDS = std.heap.page_allocator;


// write  UDS to LDA 
fn udsToLDA(vUDS: COMUDS,vLDA: *map.COMLDA) void {

    vLDA.zuds = std.fmt.allocPrint(allocUDS,
        "{s}|{s}|{s}|{s}|{s}|{s}|{s}|{s}|{s}|{s}|{d}|{}"
        ,.{
            // alpha numeric
            vUDS.zua1,
            vUDS.zua2,
            vUDS.zua3,
            vUDS.zua4,
            vUDS.zua5,
            // numérique
            vUDS.zun1,
            vUDS.zun2,
            vUDS.zun3,
            vUDS.zun4,
            vUDS.zun5,
            // other for test
            vUDS.zu8,
            vUDS.zcomit,
        }) catch unreachable;
}

// read LDA to UDS
fn ldaToUDS(vlda: map.COMLDA) COMUDS {

    var vuds : COMUDS = undefined;
    var it = std.mem.splitScalar(u8, vlda.zuds[0..], '|');
    var i : usize = 0;
    while (it.next()) |chunk| :( i += 1) {
            switch(i) {
            0  => vuds.zua1 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            1  => vuds.zua2 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            2  => vuds.zua3 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            3  => vuds.zua4 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            4  => vuds.zua5 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            5  => vuds.zun1 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            6  => vuds.zun2 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            7  => vuds.zun3 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            8  => vuds.zun4 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            9  => vuds.zun5 = std.fmt.allocPrint(allocUDS,"{s}",.{chunk}) catch unreachable,
            10 => vuds.zu8  = std.fmt.parseInt(u8,chunk,10) catch unreachable,
            11 =>{    if (std.mem.eql(u8,chunk, "true")) vuds.zcomit = true
                    else  vuds.zcomit = false;
            },
            else => continue,
        }
    }
    return vuds;
}

var pgmName : []const u8 = undefined;
var pgmPARM : []const u8 = undefined;
var nParm : usize = 0;

// const err = error.AccessDenied;

fn getPgmArgs() void {
    var args_it = try std.process.ArgIterator.initWithAllocator(allocUDS);
    defer args_it.deinit();
        while(args_it.next()) |arg|  {
        nParm += 1;
        if(nParm == 1) pgmName = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
        if(nParm == 2) pgmPARM = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
        } 
}


pub const ErrorTest = error{
    Testcontrol_errror,
};


pub fn main() !void {

    getPgmArgs();
    
    var UDS : COMUDS =initUDS();
if (nParm != 2 ) return ErrorTest.Testcontrol_errror;

var zun5 : i32 = 0;
var buf: [256]u8 = undefined;
var LDA = map.echoMmap(pgmPARM) 
            catch | err| {
            const s = @src();
            map.Perror(std.fmt.allocPrint(allocUDS,
            "\n\n\r file:{s} line:{d} column:{d} func:{s}  err:{})\n\r"
            ,.{s.file, s.line, s.column,s.fn_name,err})
             catch unreachable);
                };

            
 LDA = try map.readLDA();
 UDS = ldaToUDS(LDA);
            
    while (!LDA.abort) {
        
        if (LDA.reply == false) { 

            zun5 = try std.fmt.parseInt(i32, UDS.zun5, 10);
            zun5 += @intCast(UDS.zu8);
            buf = undefined;
            UDS.zun5  = std.fmt.bufPrintZ(&buf, "{}", .{zun5}) catch unreachable;
            LDA.reply = true;
            if ( zun5 == 10000) { UDS.zcomit = true; LDA.abort = true ;}
            udsToLDA(UDS, &LDA);
            try map.writeLDA(&LDA);
            map.lock();
        }
        if (!LDA.abort) {
            while ( true )  {
                std.posix.nanosleep(0,1_000);
                if ( !map.islock() ) break;            
            }
            LDA = try map.readLDA();
            UDS = ldaToUDS(LDA);
        }    
    }
}

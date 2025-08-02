///-----------------------
/// prog echo
///-----------------------
const std = @import("std");

const map = @import("zmmap");
const mdl = @import("callpgm");

var out = std.fs.File.stdout().writerStreaming(&.{});
pub inline fn Print( comptime format: []const u8, args: anytype) void {
    out.interface.print(format, args) catch {};
}
pub inline fn WriteAll( args: anytype) void {
    out.interface.writeAll(args) catch {};
}
fn Pause() void{

    WriteAll("\nPause\r\n");
var stdin = std.fs.File.stdin();
    var buf: [16]u8 =  undefined;
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
    WriteAll("\r\nPread");
   // initialisation communication
    var UDS = initUDS();
    var LDA = map.masterMmap() catch @panic("erreur system zmmap");
    getPgmArgs();
    
// for Test for error recovery and visibility  
// if ( nParm > 0) return ErrorTest.Testcontrol_errror;
    // parametrage  UDS
    LDA.init  = pgmName ; // programme Master
    LDA.reply = false;
    LDA.abort = false;
    UDS.zua1  = "bonjour";
    UDS.zua2  = "Nom";
    UDS.zun5  = "0";
    UDS.zu8   = 1;
    UDS.zcomit  = false;
    udsToLDA(UDS, &LDA);
    try map.writeLDA(&LDA);

    // We call the program and take over immediately. "spwan no wait
    mdl.callPgmPid("SH", "Preply", map.getParm(),false) 
                            catch |err| std.debug.panic("err: {any}",.{err});

    // Recover the process and don't forget to do kill at the end of the process.                       
    const process = mdl.getProcess();
                 
    while (!LDA.abort ) {
        while ( true)  {
            std.posix.nanosleep(0,1_000);
            if ( map.islock() ) break;
        }

        LDA = try map.readLDA();
        UDS = ldaToUDS(LDA);
        if ( LDA.reply) {
            Print("\r\nLDA.user  {s}", .{LDA.user});
            Print("\r\nLDA.Init  {s}", .{LDA.init});
            Print("\r\nLDA.Echo  {s}", .{LDA.echo});
            Print("\r\nLDA.reply {}",  .{LDA.reply});
            Print("\r\nLDA.abort {}",  .{LDA.abort});
            Print("\r\nLDA.zua1  {s}", .{UDS.zua1});
            Print("\r\nLDA.zua2  {s}", .{UDS.zua2});
            Print("\r\nLDA.zua3  {s}", .{UDS.zua3});
            Print("\r\nLDA.zun5  {s}", .{UDS.zun5});
            Print("\r\nLDA.zu8   {d}", .{UDS.zu8});
         }
        if ( !LDA.abort) {
                LDA.reply = false;
                udsToLDA(UDS, &LDA);
                try map.writeLDA(&LDA);
                map.unlock();
        }

    }
    map.released();
    // If you forget to press “kill”, the process remains Zombie until the end of your program.
    _ = std.process.Child.kill(process) catch unreachable ;
    Pause();
}

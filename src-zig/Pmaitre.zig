///-----------------------
/// prog base
///-----------------------
const std = @import("std");

const map = @import("zmmap");
const mdl = @import("callpgm");


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
    vLDA.zuds = undefined;
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

    var vuds : COMUDS = initUDS();
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

fn getPgmArgs() void {
    var args_it = try std.process.ArgIterator.initWithAllocator(allocUDS);
    defer args_it.deinit();
    while(args_it.next()) |arg|  {
        nParm += 1;
        // std.debug.print("\n{d}",.{nParm}); std.debug.print("{s}",.{arg});
        if(nParm == 1) pgmName = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
        if(nParm == 2) pgmPARM = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
    } 
}

//============================================================================================

var out = std.fs.File.stdout().writerStreaming(&.{});
pub inline fn Print( comptime format: []const u8, args: anytype) void {
    out.interface.print(format, args) catch return;
}
pub inline fn WriteAll( args: anytype) void {
    out.interface.writeAll(args) catch return;
}


var in = std.fs.File.stdin().readerStreaming(&.{});
fn Pause() void{
    WriteAll("Pause\r\n");
    var buf: [16]u8 =  [_]u8{0} ** 16;
    var c  : usize = 0;
    while (c <= 0) {
        c = in.interface.readVec(&.{&buf}) catch unreachable;
    }
}

//============================================================================================

const allocator = std.heap.page_allocator;
pub fn main() !void {


    // caller program  spanwait
    // const pgmPARM : ?[] const u8 = null;
    // try mdl.callPgmPid("APPTERM", "Mcursed", pgmPARM);
    
    WriteAll("stop 1/3 fin\r\n");
    Pause();

    // initialisation communication
    var UDS : COMUDS = initUDS();
    var LDA = map.masterMmap() catch @panic("erreur system zmmap");
    getPgmArgs();




    Print("pgmName  {s}\r\n", .{pgmName});
    Pause();
    LDA.init = pgmName;
    UDS.zua1 = "bonjour";
    UDS.zua2 = "premier test";
    UDS.zua3 = "";
    UDS.zun5 = "123456.0123";
    UDS.zcomit  = false;

    Pause();
   
        Print("\n LDA.user  {s}", .{LDA.user});
        Print("\n LDA.Init  {s}", .{LDA.init});
        Print("\n LDA.Echo  {s}", .{LDA.echo});
        Print("\n LDA.reply {}",  .{LDA.reply});
        Print("\n LDA.abort {}",  .{LDA.abort});
        Print("\n LDA.zua1  {s}", .{UDS.zua1});
        Print("\n LDA.zua2  {s}", .{UDS.zua2});
        Print("\n LDA.zua3  {s}", .{UDS.zua3});
        Print("\n LDA.zua4  {s}", .{UDS.zua4});
        Print("\n LDA.zun1  {s}", .{UDS.zun1});
        Print("\n LDA.zun2  {s}", .{UDS.zun2});
        Print("\n LDA.zun3  {s}", .{UDS.zun3});
        Print("\n LDA.zun4  {s}", .{UDS.zun4});
        Print("\n LDA.zun5  {s}", .{UDS.zun5});
        Print("\n UDS.zcomit {}\n",  .{UDS.zcomit});    Pause();

    // transmit the request
    udsToLDA(UDS, &LDA);
    try map.writeLDA(&LDA);
    Print("{s}\n", .{map.getParm()});

    WriteAll("lecture first  2 fin\r\n");
    Pause();
    
    // caller program  spanwait
    try mdl.callPgmPid("SH", "Pecho", map.getParm(),true);
    // retrive group datarea
    WriteAll("lecture retour first 3 fin\r\n");
    LDA = try map.readLDA();
    UDS = ldaToUDS(LDA);
    if (LDA.reply == true) {
        Print("\n LDA.user  {s}", .{LDA.user});
        Print("\n LDA.Init  {s}", .{LDA.init});
        Print("\n LDA.Echo  {s}", .{LDA.echo});
        Print("\n LDA.reply {}",  .{LDA.reply});
        Print("\n LDA.abort {}",  .{LDA.abort});
        Print("\n LDA.zua1  {s}", .{UDS.zua1});
        Print("\n LDA.zua2  {s}", .{UDS.zua2});
        Print("\n LDA.zua3  {s}", .{UDS.zua3});
        Print("\n LDA.zua4  {s}", .{UDS.zua4});
        Print("\n LDA.zun1  {s}", .{UDS.zun1});
        Print("\n LDA.zun2  {s}", .{UDS.zun2});
        Print("\n LDA.zun3  {s}", .{UDS.zun3});
        Print("\n LDA.zun4  {s}", .{UDS.zun4});
        Print("\n LDA.zun5  {s}", .{UDS.zun5});
        Print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
    } else  Print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
    // work end code ...

    // LDA = undefined;

    WriteAll("stop 4 fin\r\n");
    Pause();

    
    map.savEnvMmap() ;

    LDA = undefined;
    UDS = initUDS();
    LDA = map.masterMmap() catch @panic("erreur system zmmap");

    LDA.init = pgmName;
    UDS.zua1 = "bonjour";
    UDS.zua2 = "deuxiemme test";
    // transmit the request
    udsToLDA(UDS, &LDA);
    try map.writeLDA(&LDA);
    std.debug.print("lecture new  5 fin\r\n", .{});
        Print("\n LDA.user  {s}", .{LDA.user});
        Print("\n LDA.Init  {s}", .{LDA.init});
        Print("\n LDA.Echo  {s}", .{LDA.echo});
        Print("\n LDA.reply {}",  .{LDA.reply});
        Print("\n LDA.abort {}",  .{LDA.abort});
        Print("\n LDA.zua1  {s}", .{UDS.zua1});
        Print("\n LDA.zua2  {s}", .{UDS.zua2});
        Print("\n LDA.zua3  {s}", .{UDS.zua3});
        Print("\n LDA.zua4  {s}", .{UDS.zua4});
        Print("\n LDA.zun1  {s}", .{UDS.zun1});
        Print("\n LDA.zun2  {s}", .{UDS.zun2});
        Print("\n LDA.zun3  {s}", .{UDS.zun3});
        Print("\n LDA.zun4  {s}", .{UDS.zun4});
        Print("\n LDA.zun5  {s}", .{UDS.zun5});
        Print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
    // print("{s}\n", .{map.getParm()});

    WriteAll(" start new  3\r\n");
    // caller program  spanwait
    try mdl.callPgmPid("SH", "Pecho", map.getParm(),true);

    WriteAll("start new 4 fin\r\n");
    Pause();

    // retrive group datarea
    LDA = try map.readLDA();
    UDS = ldaToUDS(LDA);
    if (LDA.reply == true) {
        Print("\n LDA.user  {s}", .{LDA.user});
        Print("\n LDA.Init  {s}", .{LDA.init});
        Print("\n LDA.Echo  {s}", .{LDA.echo});
        Print("\n LDA.reply {}",  .{LDA.reply});
        Print("\n LDA.abort {}",  .{LDA.abort});
        Print("\n LDA.zua1  {s}", .{UDS.zua1});
        Print("\n LDA.zua2  {s}", .{UDS.zua2});
        Print("\n LDA.zua3  {s}", .{UDS.zua3});
        Print("\n LDA.zua4  {s}", .{UDS.zua4});
        Print("\n LDA.zun1  {s}", .{UDS.zun1});
        Print("\n LDA.zun2  {s}", .{UDS.zun2});
        Print("\n LDA.zun3  {s}", .{UDS.zun3});
        Print("\n LDA.zun4  {s}", .{UDS.zun4});
        Print("\n LDA.zun5  {s}", .{UDS.zun5});
        Print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
    } else Print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
    // work end code ...

    WriteAll("lecture retour new 5\r\n");
    Pause();


    
    map.rstEnvMmap();
    // end communication
    // retrive group datarea
    WriteAll("lecture retour first 6\r\n");
    LDA = try map.readLDA();
    UDS = ldaToUDS(LDA);
    if (LDA.reply == true) {
        Print("\n LDA.user  {s}", .{LDA.user});
        Print("\n LDA.Init  {s}", .{LDA.init});
        Print("\n LDA.Echo  {s}", .{LDA.echo});
        Print("\n LDA.reply {}",  .{LDA.reply});
        Print("\n LDA.abort {}",  .{LDA.abort});
        Print("\n LDA.zua1  {s}", .{UDS.zua1});
        Print("\n LDA.zua2  {s}", .{UDS.zua2});
        Print("\n LDA.zua3  {s}", .{UDS.zua3});
        Print("\n LDA.zua4  {s}", .{UDS.zua4});
        Print("\n LDA.zun1  {s}", .{UDS.zun1});
        Print("\n LDA.zun2  {s}", .{UDS.zun2});
        Print("\n LDA.zun3  {s}", .{UDS.zun3});
        Print("\n LDA.zun4  {s}", .{UDS.zun4});
        Print("\n LDA.zun5  {s}", .{UDS.zun5});
        Print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
    } else Print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
    // end communication
    map.released();
    WriteAll("stop fin\r\n");
    Pause();

}

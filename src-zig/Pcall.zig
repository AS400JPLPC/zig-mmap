///-----------------------
/// prog base
///-----------------------
const std = @import("std");

const map = @import("zmmap");
const mdl = @import("callpgm");

const deb_Log = @import("logger").openFile;   // open  file
const end_Log = @import("logger").closeFile;  // close file
const plog   = @import("logger").scoped;      // print file 




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
// Common core for communication between two programs.

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
        //std.debug.print("\n{d}",.{nParm}); std.debug.print("{s}",.{arg});
        if(nParm == 1) pgmName = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
        if(nParm == 2) pgmPARM = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
    }
}

//============================================================================================

pub fn main() !void {


    //======================================================
    // spéciale test call pgm
    // test calling not parameter
    // émulation décisionel
    // const pgmPARM_null : ?[] const u8 = null;
    // // caller program  spanwait
    // try mdl.callPgmPid("APPTERM", "Mcursed",KEY);
    // APPTERM = terminal libvte
    // SH ./bin.sh
    //=====================================================



    // initialisation communication
    var UDS = initUDS();
    var LDA = map.masterMmap() catch @panic("erreur system zmmap");
    getPgmArgs();


    // parametrage  UDS
    LDA.init  = pgmName ; // programme Master
    UDS.zua1  = "bonjour";
    UDS.zua2  = "Nom";
    UDS.zun5  = "123456.0123";
    UDS.zu8   = 25;
    UDS.zcomit  = false;
  deb_Log("Pcall.txt");
 
    plog(.main).debug("ecriture USD to LDA\r\n",.{});
        plog(.main).debug("\n LDA.user  {s}", .{LDA.user});
        plog(.main).debug("\n LDA.Init  {s}", .{LDA.init});

        plog(.main).debug("\n LDA.Echo  {s}", .{LDA.echo});
        plog(.main).debug("\n LDA.reply {}",  .{LDA.reply});
        plog(.main).debug("\n LDA.abort {}",  .{LDA.abort});
        
        plog(.main).debug("\n UDS.zua1  {s}", .{UDS.zua1});
        plog(.main).debug("\n UDS.zua2  {s}", .{UDS.zua2});
        plog(.main).debug("\n UDS.zua3  {s}", .{UDS.zua3});
        plog(.main).debug("\n UDS.zua4  {s}", .{UDS.zua4});
        plog(.main).debug("\n UDS.zua5  {s}", .{UDS.zua5});
        
        plog(.main).debug("\n UDS.zun1  {s}", .{UDS.zun1});
        plog(.main).debug("\n UDS.zun2  {s}", .{UDS.zun2});
        plog(.main).debug("\n UDS.zun3  {s}", .{UDS.zun3});
        plog(.main).debug("\n UDS.zun4  {s}", .{UDS.zun4});
        plog(.main).debug("\n UDS.zun5  {s}", .{UDS.zun5});
 end_Log();
  
    udsToLDA(UDS, &LDA);
    try map.writeLDA(&LDA);


    // calling program ECHO  spanwait:


    mdl.callPgmPid("APPTERM", "Mcursed", map.getParm(),true) 
                            catch |err| std.debug.panic("err: {any}",.{err});
  
    // retrive group datarea
    LDA = try map.readLDA();
    UDS = ldaToUDS(LDA);
  deb_Log("Pcall2.txt");
   
 plog(.reply).debug("\n map.getParm {s}", .{map.getParm()});

 Pause();


 
    if (LDA.reply == true) {
        plog(.reply).debug("\n LDA.user  {s}", .{LDA.user});
        plog(.reply).debug("\n LDA.Init  {s}", .{LDA.init});

        plog(.reply).debug("\n LDA.Echo  {s}", .{LDA.echo});
        plog(.reply).debug("\n LDA.reply {}",  .{LDA.reply});
        plog(.reply).debug("\n LDA.abort {}",  .{LDA.abort});
        
        plog(.reply).debug("\n UDS.zua1  {s}", .{UDS.zua1});
        plog(.reply).debug("\n UDS.zua2  {s}", .{UDS.zua2});
        plog(.reply).debug("\n UDS.zua3  {s}", .{UDS.zua3});
        plog(.reply).debug("\n UDS.zua4  {s}", .{UDS.zua4});
        plog(.reply).debug("\n UDS.zua5  {s}", .{UDS.zua5});
        
        plog(.reply).debug("\n UDS.zun1  {s}", .{UDS.zun1});
        plog(.reply).debug("\n UDS.zun2  {s}", .{UDS.zun2});
        plog(.reply).debug("\n UDS.zun3  {s}", .{UDS.zun3});
        plog(.reply).debug("\n UDS.zun4  {s}", .{UDS.zun4});
        plog(.reply).debug("\n UDS.zun5  {s}", .{UDS.zun5});
        
        plog(.reply).debug("\n UDS.zu8   {d}", .{UDS.zu8});
        plog(.reply).debug("\n UDS.zcomit {}\n",  .{UDS.zcomit});

        
    } else plog(.reply).debug("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
    
    // work end code ...
    
    map.released();
    plog(.main).info("\nstop fin\r\n",.{});

    end_Log();
    Pause();
                        
}

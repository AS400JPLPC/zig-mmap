**Attention ZIG  0.15.2   incompatible avec  0.14.1 **



I present to you ZMMAP, a utilization of MMAP with Zig.

First, let me talk about \*LDA, a function available with IBM's OS AS400. It's a "Local Data Area" that allows for freely defining a structured type for communication with another entity, such as 2 programs or jobs.  
  
Typically, in an enterprise, we define a structure covering a very wide common spectrum. So, to understand it well, we have a CRYPTO module, a CALLPGM module, an MMAP module, and a UDS structure (Unified Data Structure, referencing IBM).  
  
**MMAP:**  
A memory space with a record like a file, providing ultra-fast access. The commonly acknowledged issue is the confidential insecurity of the document. That's why I'm using Zig's cryptography, referencing aes\_gcm.zig.  
**  
CALLPGM**:  
A module that allows calling another independent process using the function std.ChildProcess.spawnAndWait, enabling modular programming.  
  
**CRYPTO**:  
won't discuss the cryptographic module. It's a copy I took from the master of "Zig-lang" and adapted where only the data is taken into account. For more information, please visit the "Zig-lang" website.

**Process** :

The master program needs to retrieve a key, for example, the customer number during an order taking process. The customer file is maintained by the accounting department, so it will request it from the "visu" program, which will either send back the customer number or indicate that it cannot fulfill the request.  
  
Let's go into more detail:

Module zmmap.zig To handle MMAP files, we require a unique key that is valid only once. If you need more, please ensure you have a real-time operating system.  
  
const timesStamp\_ms: u64 = @bitCast(std.time.milliTimestamp());  
On large systems with over 5000 users in real-time, I've never encountered any issues with this.  
  
This key will allow the generation of 5 MMAP files:

*   •KEY.timesStamp = the key for cryptography 
    
*   •NONCE.timesStamp = its counterpart for cryptography 
    
*   •TAG.timesStamp = the security key for cryptography 
    

Often in discussions on forums related to C/C++ or other languages, the issue of confidentiality was raised because cryptography was not yet something common, especially with the SHARED option.  
  
The LDA consists of two parts, hence two files:

LCI: local communication internal

*   •reply = yes, I respond to the request or no, I haven't found it. 
    
*   •abord = allows to indicate that I quit everything to return not to the calling program but to the main menu. 
    
*   •user 
    
    *   •init = name of the calling program. 
        
    *   •echo = name of the called program. 
        

UDS: zuds = \[\]const u8 containing the entire UDS structure. A section where fields for the request and response are located, including a field separator '|'.  
  
UDS.timesStamp = the encrypted UDS structure LOG.timesStamp = fields allowing tracking

Initially, I had a single LDA file, but encryption made it difficult for me with two field separators, and I wanted to maintain the independence of the UDS structure. So, I separated the LOG and UDS parts into two files.

Don't worry, the response times are astounding.

Process of the master program:

*   •// Communication initialization  
    
    *   •var UDS: COMUDS = initUDS();  
        I created a source file UDS.zig that I copied into both programs Pcall and Ecurses for the example to understand and test... But this is not the solution I will take. I prefer a more complex standard module for all my applications. 
        
    *   •var LDA = map.masterMmap()  
        This line creates the files, initializes the cryptography context, and initializes the LDA. 
        
    *   •getPgmArgs();  
        This function retrieves the name of the program and puts it into the LDA.init field. 
        
*   •The program waits for the name in LDA.zua3. The rest is for testing the fields.  
    // Setting up UDS parameters  
    LDA.init = pgmName; // Master program  
    UDS.zua1 = "Bonjour";  
    UDS.zua2 = "Nom";  
    UDS.zun5 = "123456.0123";  
    UDS.zu8 = 25;  
    UDS.zcomit = false; 
    
*   •The LDA is written with:  
    map.writeLDA(&LDA); 
    
*   •Then, control is passed to the Ecursed program:  
    try mdl.callPgmPid("APPTERM", "Ecursed", map.getParm()); 
    
*   •Here, "APPTERM" is a program that constructs a terminal using the "libvte3" library. This terminal provides you with the ability to manage "ALT-F4" and other functions, and opens a console with the program name ("Ecursed" being an interactive program) and its parameter.  
    I have not translated it into Zig language; it is written in "C/C++," very simple and easy to read, requiring calls to libraries written in "C" and secure.  
    The getParm() function returns the TimesSampt that was used to initialize the "mmap" files. 
    
*   •It is possible to replace "APPTERM" with "sh" to communicate with a batch-type program that does not require interactive mode.  
    For "sh" type:  
    args = (char\*\[\]) { "/bin/sh", "-c", cmd };  
    "sh" type is simpler compared to "APPTERM", which is more complex. 
    
*   •Then, we retrieve the LDA:  
    LDA = map.readLDA();  
    UDS = ldaToUDS(LDA);  
    Next, we delete the TAG, LOG, and UDS files:  
    closeLDA(); 
    
*   •This marks the end of the conversation between processes. 
    

Process of the ECHO program:

*   •Retrieve the name of the called program and the key (TimesStamp parameter):  
    getPgmArgs();  
    Initialize the UDS:  
    var UDS : COMUDS = initUDS();  
    var LDA = map.echoMmap(pgmPARM);  
    This line opens all the MMAP files,  
    reads the KEY and NONCE files, and then deletes them. 
    
*   •We retrieve the LDA and UDS:  
    LDA = map.readLDA();  
    UDS = ldaToUDS(LDA); 
    

// ---- work --------  
// ---- end work----

*   •Here's a simple example of writing to the LDA:  
      
    LDA.init = "Ecursed";                 // Set the program name  
      
    UDS.zua1 = "Hello";                 // Set UDS fields  
    UDS.zua2 = "Jean-Pierre";  
    UDS.zun5 = "0";  
    UDS.zu8 = 72;  
    UDS.zcomit = true;  
      
    udsToLDA(UDS, &LDA);  
      
    map.writeLDA(&LDA); // Write to LDA 
    
*   •End of the ECHO program. 
    

Annexe :

In the same job, you might need an already active request.

You need to back up.

 savEnvMmap()

That saves the entire context of the initial request.  
  
Then you reset the new communication.        LDA = undefined;

 UDS = initUDS();

 LDA = map.masterMmap() catch @panic("erreur system zmmap");  
  
 Code…….

To return to the initial point.

 map.rstEnvMmap();

        It restores and cleans the files.

 To complete the return transaction, respond to the caller.

 LDA = map.readLDA();

 UDS = ldaToUDS(LDA)  
  
 Code…….

End of initial program, execute releazed()  
  
The described process involves managing communications between different programs in an environment where multiple programs can be running simultaneously.

Here's  interpretation:

1.  1.The first part indicates that there can be multiple communications between different programs (A, B, C, X) in a system. 
    
2.  2.To manage these communications, it's necessary to save the complete context of the initial request for each program. 
    
3.  3.Subsequently, the process resets the communication to handle a new request, ensuring that all variables and parameters are properly configured for the new process. 
    
4.  4.When a program returns to the initial point after a series of communications, it needs to restore and clean files to ensure system integrity. 
    
5.  5.The transaction is finalized by responding to the caller, reading previously saved data, and converting it into a usable format. 
    

This process appears to be an organized way of managing interactions between different programs in a complex computing environment.<BR />
<BR />
<BR />

<BR />

TEST COMPLEX  child suspend not wait:  
<BR />
**maitre**:<BR />
  
```  
  
///-----------------------
/// prog echo
///-----------------------
const std = @import("std");

const map = @import("zmmap");
const mdl = @import("callpgm");

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
  
```  
  
<BR />
**child:**<BR />
  
```  
  

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
  
```  
  
*   •upgrade  2025-08-01.<BR />
&nbsp;&nbsp;&nbsp;&larr;&nbsp;zig version   0.15.dev  -->  Token<BR /> 


<BR />
*   •upgrade  2025-08-02.<BR />   
*Alignment of Print WriteAll functions in all modules and Pause.<BR />
This is for my tests, to see how it goes and check, and to see how the memory is managed.
<BR /><BR />

*   •upgrade  2025-08-23.<BR />   
version 0.15.1 zig
<BR /><BR />

*   •upgrade  2025-12-25.<BR />   
version 0.15.2 zig
<BR /><BR />



    
<br/>
-2025-11-18  17:00 regression  Regression back to version 15.2<br/>
<br/>

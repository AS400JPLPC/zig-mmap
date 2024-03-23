	///-----------------------
	/// prog base
	/// zig 0.12.0 dev
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
			0  => vuds.zua1 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			1  => vuds.zua2 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			2  => vuds.zua3 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			3  => vuds.zua4 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			4  => vuds.zua5 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			
			5  => vuds.zun1 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			6  => vuds.zun2 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			7  => vuds.zun3 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			8  => vuds.zun4 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			9  => vuds.zun5 = std.fmt.allocPrintZ(allocUDS,"{s}",.{chunk}) catch unreachable,
			
			10 => vuds.zu8  = std.fmt.parseInt(u8,chunk,10) catch unreachable,
			11 =>{	if (std.mem.eql(u8,chunk, "true")) vuds.zcomit = true
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

const out = std.io.getStdOut();
var   w   = out.writer();


const stdin = std.io.getStdIn().reader();
var buf: [3]u8 = undefined;
const allocator = std.heap.page_allocator;
pub fn main() !void {


	// caller program  spanwait
	// const pgmPARM : ?[] const u8 = null;
	// try mdl.callPgmPid("APPTERM", "Mcursed", pgmPARM);
	
	std.debug.print("stop 1/3 fin\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');

	// initialisation communication
	var UDS : COMUDS = initUDS();
	var LDA = map.masterMmap() catch @panic("erreur system zmmap");
	getPgmArgs();

	try	w.print("pgmName  {s}\r\n", .{pgmName});

	LDA.init = pgmName;
	UDS.zua1 = "bonjour";
	UDS.zua2 = "premier test";
	UDS.zua3 = "";
	UDS.zun5 = "123456.0123";
	UDS.zcomit  = false;
	
		try	w.print("\n LDA.user  {s}", .{LDA.user});
		try	w.print("\n LDA.Init  {s}", .{LDA.init});
		try	w.print("\n LDA.Echo  {s}", .{LDA.echo});
		try	w.print("\n LDA.reply {}",  .{LDA.reply});
		try	w.print("\n LDA.abort {}",  .{LDA.abort});
		try	w.print("\n LDA.zua1  {s}", .{UDS.zua1});
		try	w.print("\n LDA.zua2  {s}", .{UDS.zua2});
		try	w.print("\n LDA.zua3  {s}", .{UDS.zua3});
		try	w.print("\n LDA.zua4  {s}", .{UDS.zua4});
		try	w.print("\n LDA.zun1  {s}", .{UDS.zun1});
		try	w.print("\n LDA.zun2  {s}", .{UDS.zun2});
		try	w.print("\n LDA.zun3  {s}", .{UDS.zun3});
		try	w.print("\n LDA.zun4  {s}", .{UDS.zun4});
		try	w.print("\n LDA.zun5  {s}", .{UDS.zun5});
		try	w.print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
	// transmit the request
	udsToLDA(UDS, &LDA);
	map.writeLDA(&LDA);
	try	w.print("{s}\n", .{map.getParm()});

	std.debug.print("lecture first  2 fin\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');

	// caller program  spanwait
	try mdl.callPgmPid("SH", "Pecho", map.getParm());
	// retrive group datarea
	try	w.print("lecture retour first 3 fin\r\n", .{});
	LDA = map.readLDA();
	UDS = ldaToUDS(LDA);
	if (LDA.reply == true) {
		try	w.print("\n LDA.user  {s}", .{LDA.user});
		try	w.print("\n LDA.Init  {s}", .{LDA.init});
		try	w.print("\n LDA.Echo  {s}", .{LDA.echo});
		try	w.print("\n LDA.reply {}",  .{LDA.reply});
		try	w.print("\n LDA.abort {}",  .{LDA.abort});
		try	w.print("\n LDA.zua1  {s}", .{UDS.zua1});
		try	w.print("\n LDA.zua2  {s}", .{UDS.zua2});
		try	w.print("\n LDA.zua3  {s}", .{UDS.zua3});
		try	w.print("\n LDA.zua4  {s}", .{UDS.zua4});
		try	w.print("\n LDA.zun1  {s}", .{UDS.zun1});
		try	w.print("\n LDA.zun2  {s}", .{UDS.zun2});
		try	w.print("\n LDA.zun3  {s}", .{UDS.zun3});
		try	w.print("\n LDA.zun4  {s}", .{UDS.zun4});
		try	w.print("\n LDA.zun5  {s}", .{UDS.zun5});
		try	w.print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
	} else try	w.print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
	// work end code ...

	// LDA = undefined;

	try	w.print("stop 4 fin\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');

	map.savEnvMmap() ;

	LDA = undefined;
	UDS = initUDS();
	LDA = map.masterMmap() catch @panic("erreur system zmmap");

	LDA.init = pgmName;
	UDS.zua1 = "bonjour";
	UDS.zua2 = "deuxiemme test";
	// transmit the request
	udsToLDA(UDS, &LDA);
	map.writeLDA(&LDA);
	std.debug.print("lecture new  5 fin\r\n", .{});
		try	w.print("\n LDA.user  {s}", .{LDA.user});
		try	w.print("\n LDA.Init  {s}", .{LDA.init});
		try	w.print("\n LDA.Echo  {s}", .{LDA.echo});
		try	w.print("\n LDA.reply {}",  .{LDA.reply});
		try	w.print("\n LDA.abort {}",  .{LDA.abort});
		try	w.print("\n LDA.zua1  {s}", .{UDS.zua1});
		try	w.print("\n LDA.zua2  {s}", .{UDS.zua2});
		try	w.print("\n LDA.zua3  {s}", .{UDS.zua3});
		try	w.print("\n LDA.zua4  {s}", .{UDS.zua4});
		try	w.print("\n LDA.zun1  {s}", .{UDS.zun1});
		try	w.print("\n LDA.zun2  {s}", .{UDS.zun2});
		try	w.print("\n LDA.zun3  {s}", .{UDS.zun3});
		try	w.print("\n LDA.zun4  {s}", .{UDS.zun4});
		try	w.print("\n LDA.zun5  {s}", .{UDS.zun5});
		try	w.print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
	// print("{s}\n", .{map.getParm()});

	try	w.print(" start new  3\r\n", .{});
	// caller program  spanwait
	try mdl.callPgmPid("SH", "Pecho", map.getParm());
		try	w.print("start new 4 fin\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
	// retrive group datarea
	LDA = map.readLDA();
	UDS = ldaToUDS(LDA);
	if (LDA.reply == true) {
		try	w.print("\n LDA.user  {s}", .{LDA.user});
		try	w.print("\n LDA.Init  {s}", .{LDA.init});
		try	w.print("\n LDA.Echo  {s}", .{LDA.echo});
		try	w.print("\n LDA.reply {}",  .{LDA.reply});
		try	w.print("\n LDA.abort {}",  .{LDA.abort});
		try	w.print("\n LDA.zua1  {s}", .{UDS.zua1});
		try	w.print("\n LDA.zua2  {s}", .{UDS.zua2});
		try	w.print("\n LDA.zua3  {s}", .{UDS.zua3});
		try	w.print("\n LDA.zua4  {s}", .{UDS.zua4});
		try	w.print("\n LDA.zun1  {s}", .{UDS.zun1});
		try	w.print("\n LDA.zun2  {s}", .{UDS.zun2});
		try	w.print("\n LDA.zun3  {s}", .{UDS.zun3});
		try	w.print("\n LDA.zun4  {s}", .{UDS.zun4});
		try	w.print("\n LDA.zun5  {s}", .{UDS.zun5});
		try	w.print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
	} else try	w.print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
	// work end code ...

		try	w.print("lecture retour new 5\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');

	map.rstEnvMmap();
	// end communication
	// retrive group datarea
	try	w.print("lecture retour first 6\r\n", .{});
	LDA = map.readLDA();
	UDS = ldaToUDS(LDA);
	if (LDA.reply == true) {
		try	w.print("\n LDA.user  {s}", .{LDA.user});
		try	w.print("\n LDA.Init  {s}", .{LDA.init});
		try	w.print("\n LDA.Echo  {s}", .{LDA.echo});
		try	w.print("\n LDA.reply {}",  .{LDA.reply});
		try	w.print("\n LDA.abort {}",  .{LDA.abort});
		try	w.print("\n LDA.zua1  {s}", .{UDS.zua1});
		try	w.print("\n LDA.zua2  {s}", .{UDS.zua2});
		try	w.print("\n LDA.zua3  {s}", .{UDS.zua3});
		try	w.print("\n LDA.zua4  {s}", .{UDS.zua4});
		try	w.print("\n LDA.zun1  {s}", .{UDS.zun1});
		try	w.print("\n LDA.zun2  {s}", .{UDS.zun2});
		try	w.print("\n LDA.zun3  {s}", .{UDS.zun3});
		try	w.print("\n LDA.zun4  {s}", .{UDS.zun4});
		try	w.print("\n LDA.zun5  {s}", .{UDS.zun5});
		try	w.print("\n UDS.zcomit {}\n",  .{UDS.zcomit});
	} else try	w.print("\n\n\nLDA.reply : {} not found request ", .{LDA.reply});
	// end communication
	map.released();
	try	w.print("stop fin\r\n", .{});
	buf = [_]u8{0} ** 3;
	_ = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
}

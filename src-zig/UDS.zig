	//---------------------------
	// structure UDS
	//---------------------------
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

	const vuds : COMUDS =.{
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


// write  UDS to ZLDA 
fn udsToLDA(vUDS: COMUDS,vLDA: *map.COMLDA) void {

	vLDA.zlda = std.fmt.allocPrint(allocUDS,
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

// read ZLDA to UDS
fn ldaToUDS(vlda: map.COMLDA) COMUDS {

	var vuds : COMUDS = undefined;
	var it = std.mem.splitScalar(u8, vlda.zlda[0..], '|');
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


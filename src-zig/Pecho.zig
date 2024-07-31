	///-----------------------
	/// prog echo
	/// zig 0.12.0 dev
	///-----------------------
const std = @import("std");

const map = @import("zmmap");



const deb_Log = @import("logger").openFile;   // open  file
const end_Log = @import("logger").closeFile;  // close file
const plog	  = @import("logger").scoped;      // print file 

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
			plog(.Panel).warn("\n{d}\n",.{nParm}); plog(.Panel).warn("\n{s}\n",.{arg});
		if(nParm == 1) pgmName = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
		if(nParm == 2) pgmPARM = std.fmt.allocPrint(allocUDS,"{s}",.{arg}) catch unreachable;
	} 
}
pub fn main() !void {
	deb_Log("Pecho.txt");
	plog(.main).warn("Begin\n", .{});

	getPgmArgs();
	plog(.Panel).warn("nParm {d}\n",.{nParm});
	
	var UDS : COMUDS =initUDS();
if (nParm == 2 ) {
	plog(.Panel).warn("echoMmap\n",.{});
	var LDA = map.echoMmap(pgmPARM) 
				catch  @panic(" error readMmap  not init communication call service informatique");
	
	plog(.Panel).warn("readLDA\n",.{});
	LDA = map.readLDA();
	
	UDS = ldaToUDS(LDA);
plog(.Panel).warn("\nldaToUDS(",.{});
plog(.Panel).warn("{d}",.{nParm});
plog(.Panel).warn("{s}",.{LDA.zuds});
plog(.Panel).warn("{}",.{LDA.reply});
plog(.Panel).warn("{}",.{LDA.abort});
		// work traitement:
		// end traitement
		LDA.echo = pgmName;
		LDA.reply = true;
		UDS.zua1 = "je n'ais pas votre message";
		UDS.zua3 = "Marie";
		UDS.zun5 = "0";
		// send group datarea
		udsToLDA(UDS, &LDA);

plog(.Panel).warn("\nudsToLDA",.{});
plog(.Panel).warn("{s}",.{LDA.zuds});
plog(.Panel).warn("{}",.{LDA.reply});
plog(.Panel).warn("{}",.{LDA.abort});

plog(.Panel).warn("writeLDA\n",.{});
		map.writeLDA(&LDA);
		//defer allocator.free(pgmPARM);

end_Log();


	} else {
		// work traitement

		// end traitement
	}
}

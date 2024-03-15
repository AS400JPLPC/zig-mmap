I present to you ZMMAP, a utilization of MMAP with Zig.

First, let me talk about \*LDA, a function available with IBM's OS AS400. It's a "Local Data Area" that allows for freely defining a structured type for communication with another entity, such as 2 programs or jobs.  
  
Typically, in an enterprise, we define a structure covering a very wide common spectrum. So, to understand it well, we have a CRYPTO module, a CALLPGM module, an MMAP module, and a UDS structure (Unified Data Structure, referencing IBM).  
  
MMAP:  
A memory space with a record like a file, providing ultra-fast access. The commonly acknowledged issue is the confidential insecurity of the document. That's why I'm using Zig's cryptography, referencing aes\_gcm.zig.  
  
CALLPGM:  
A module that allows calling another independent process using the function std.ChildProcess.spawnAndWait, enabling modular programming.  
  
CRYPTO:  
won't discuss the cryptographic module. It's a copy I took from the master of "Zig-lang" and adapted where only the data is taken into account. For more information, please visit the "Zig-lang" website.

Process :

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

LOG:

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
    Cinematic:  
<BR />
 I need to record an order. I go to the order program. I need to check the client (this program is independent); it will give me the client number. In the visualization program, I notice there is an accounting consultation tag. I navigate to a menu where I can check if the client is not in dispute, then I return and proceed to see how their orders are settled, etc. This is what the "ZMMAP" tool can allow.

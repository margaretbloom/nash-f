# NASH-F
## NO-LIB (uses only syscalls), ASSEMBLY WRITTEN, SMALL (229 bytes), HTTP-ONLY (no TLS/SSL), FIXED (only send a static response) SERVER

This code is **ABSOLUTELY NOT** meant to be used for any purpose.
It was written for fun after reading [this](https://stackoverflow.com/questions/67445637/why-doesnt-this-assembly-http-server-work?) question on Stackoverflow.

The final size of the ELF is 229 bytes.   
Section headers are stripped, `--omagic` is used to make a single program header, no debug or symbol sections are created.  
The source is assembled with `nasm` and linked with `ld`, you can look in the `Makefile` to see their command lines.  
While `ld` already produce a small sized ELF, the final cut down is done by an ad-hoc (and very ugly and unsafe) C program that i called `short`.  
The source is in `short.c`, it just removes the section headers and keep only the data up to the biggest offset covered by a program header (it 
assumes these come before the section headers).  

At least 4 more bytes can be shaved off easily from the code at the cost of making it less configurable and using LFs in the HTTP response.  
Surely the size can be further shrinked down by golfing the code (which I didn't really try hard to do), the current source is a good compromise
between readability, configurability and size.  
It will also correctly work, close the connection and avoid forking a new process since sending a very small, static HTTP response is way faster than
spawning a new worker.
All things the original [code](https://github.com/sigmonsays/smallest-docker-httpd) failed to do.

# Configuration

The server will listen on 0.0.0.0:8800 (just like the original httpd example linked above).
You can easily change that by editing the last line of the source. Particularly, you'll find a line `MAKE_PORT 8800` that can be altered to 
change the port and a **commented** `MAKE_INTERFACE 0, 0, 0, 0` line that can be used to pass the IPv4 of the interface to listen to (each octect
separated by a comma).  
The line is commented to exploit an ugly hack to save 4 bytes. Decommenting it will make the binary 4 bytes longer. 

# Build

Just run

   make
   
It will build the `httpd2` binary file (along with `httpd2.o` and `short`).

# Docker image

I don't have docker to test the image or anything.
I suppose you can create an image with:

    tar c httpd2 | docker import - nashf

This should only include the `httpd2` binary.
**NOTE** `httpd2` doesn't need any dependency library or any file, you don't need to use a base distribution image.
 

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>

#ifndef MAX_SIZE
  #define MAX_SIZE 4096
#endif

union buffer_t
{
	uint8_t data8[MAX_SIZE];
	uint16_t data16[MAX_SIZE/2];
	uint32_t data32[MAX_SIZE/4];
} buffer;

#define offset8(x)  (x)
#define offset32(x) ((x) / 4)
#define offset16(x) ((x) / 2)

int main(int argc, char** argv)
{
	if (argc != 2)
		return fprintf(stderr, "Usage: short ELF\n"), 128;
		
	FILE* f = fopen(argv[1], "rb");
	if ( ! f)
		return fprintf(stderr, "Cannot open %s for read: %s (%d)\n", argv[1], strerror(errno), errno), 1;

	long size = fread(buffer.data8, 1, MAX_SIZE, f);
	
	if (size == 0)
	{
		fclose(f);
		return fprintf(stderr, "Cannot read %s: %s (%d)\n", argv[1], strerror(errno), errno), 1;
	}
	
	if (size == MAX_SIZE)
	{
		fclose(f);
		return fprintf(stderr, "File is too big, max file size is %u\n", MAX_SIZE), 2;
	}
	
	if (size < 0x34)
	{
		fclose(f);
		return fprintf(stderr, "File is too small to be an ELF\n"), 3;
	}
	
	fclose(f);
	
	//Get program header offset
	uint32_t ph_off = buffer.data32[offset32(0x1c)];
	
	//Clean sections number and size
	buffer.data32[offset32(0x30)] = 0;
	//Clean section header offset
	buffer.data32[offset32(0x20)] = 0;
	
	//Find the needed file size by scanning all program headers
	uint32_t file_size = 0, ph_size = buffer.data16[offset16(0x2e)];
	
	for (uint16_t i = 0; i < buffer.data16[offset16(0x2c)]; i++)
	{
		uint32_t last_byte = buffer.data32[offset32(ph_off+i*ph_size+4)] + buffer.data32[offset32(ph_off+i*ph_size+16)];
		
		if (last_byte > file_size)
			file_size = last_byte;
	}
		
	//Rewrite the modified elf up to the needed size
	f = fopen(argv[1], "wb");
	if ( ! f)
		return fprintf(stderr, "Cannot open %s for write: %s (%d)\n", argv[1], strerror(errno), errno), 4;
		
	if (fwrite(buffer.data8, file_size, 1, f) != 1)
	{
		fclose(f);
		return fprintf(stderr, "Cannot write %s: %s (%d)\n", argv[1], strerror(errno), errno), 4;
	}
		
	fclose(f);
	
	return 0;
		
}

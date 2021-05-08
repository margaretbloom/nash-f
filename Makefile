httpd2: httpd2.o short
	ld -z max-page-size=4 --strip-all --omagic -melf_i386 $< -o $@
	./short httpd2

httpd2.o: httpd2.asm
	nasm -felf32 $^ -o $@
	
short: short.c
	gcc -Wall -Wextra -Wpedantic $^ -o $@

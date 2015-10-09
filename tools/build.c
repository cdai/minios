#include <stdio.h>		/* fprintf */
#include <string.h>
#include <stdlib.h>		/* exit */
#include <sys/types.h>	/* unistd.h needs this */
#include <unistd.h>		/* read/write */
#include <fcntl.h>


#define BUFFER_SIZE 1024

#define SETUP_SECTS 4	/* max number of sectors of setup */
#define STRINGIFY(x) #x /* cat string */

#define GCC_HEADER 1024 /* GCC header length */
#define SYS_SIZE 0x2000 /* max system length (SYS_SIZE*16=128KB) */


void die(const char *str)
{
	fprintf(stderr, "%s\n", str);
	exit(1);
}

void usage()
{
	die("Usage: build bootsect setup system [> image]");
}

void copy_bootsect(char const *filename, char *buf)
{
	int c, fd;

	if ((fd = open(filename, O_RDONLY, 0)) < 0)
		die("Unable to open 'bootsect'");

	for (c = 0; c < BUFFER_SIZE; c++)
		buf[c] = 0;

	c = read(fd, buf, BUFFER_SIZE);

	close(fd);

	fprintf(stderr, "'bootsect' is %d bytes.\n", c);
	if (c != 512)
		die("'bootsect' must be exactly 512 bytes");

	if ((*(unsigned short *)(buf + 510)) != 0xAA55)
		die("'bootsect' hasn't got boot flag (0xAA55)");

	c = write(1, buf, 512);
	if (c != 512)
		die("Write call failed");
	
}

void copy_setup(char const *filename, char *buf)
{
	int c, i, fd;

	if ((fd = open(filename, O_RDONLY, 0)) < 0)
		die("Unable to open 'setup'");

	for (i = 0; (c = read(fd, buf, BUFFER_SIZE)) > 0; i += c)
		if (write(1, buf, c) != c)
			die("Write call failed");
	close(fd);

	fprintf(stderr, "'setup' is %d bytes\n", i);
	if (i > SETUP_SECTS * 512)
		die("'setup' exceeds " STRINGIFY(SETUP_SECTS) " sectors");

	// Fill '\0' if smaller than max bytes
	for (c = 0; c < BUFFER_SIZE; c++)
		buf[c] = 0;

	while(i < SETUP_SECTS * 512) {
		c = SETUP_SECTS * 512 - i;
		if (c > BUFFER_SIZE)
			c = BUFFER_SIZE;
		if (write(1, buf, c) != c)
			die("Write call failed");
		i += c;
	}
}

void copy_system(char const *filename, char *buf)
{
	int c, i, fd;

	if ((fd = open(filename, O_RDONLY, 0)) < 0)
		die("Unable to open 'system'");

	/*if (read(fd, buf, GCC_HEADER) != GCC_HEADER)
		die("Unable to read header of 'system'");

	if (((long *) buf)[5] != 0)
		die("Non-GCC header of 'system'");*/

	for (i = 0; (c = read(fd, buf, BUFFER_SIZE)) > 0; i += c)
		if (write(1, buf, c) != c)
			die("Write call failed");
	close(fd);

	fprintf(stderr, "'system' is %d bytes\n", i);
	if (i > SYS_SIZE * 16)
		die("'system' is too big");
}

int main(int argc, char const *argv[])
{
	char buf[BUFFER_SIZE];

	if (argc != 4)
		usage();	

	copy_bootsect(argv[1], buf);
	copy_setup(argv[2], buf);
	copy_system(argv[3], buf);

	return 0;
}
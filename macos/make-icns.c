#include <arpa/inet.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void
write_u32 (FILE *output, uint32_t value)
{
    uint32_t big_endian = htonl (value);

    if (fwrite (&big_endian, sizeof (big_endian), 1, output) != 1) {
        perror ("fwrite");
        exit (1);
    }
}

static long
file_size (const char *path)
{
    FILE *file = fopen (path, "rb");
    long size;

    if (!file) {
        perror (path);
        exit (1);
    }
    if (fseek (file, 0, SEEK_END) != 0 || (size = ftell (file)) < 0) {
        perror (path);
        exit (1);
    }
    fclose (file);
    return size;
}

int
main (int argc, char **argv)
{
    FILE *output;
    uint64_t total_size = 8;
    int i;

    if (argc < 3 || ((argc - 2) % 2) != 0) {
        fprintf (stderr, "usage: %s OUTPUT TYPE PNG [TYPE PNG ...]\n", argv[0]);
        return 2;
    }

    for (i = 2; i < argc; i += 2) {
        long size;

        if (strlen (argv[i]) != 4) {
            fputs ("ICNS chunk type must contain four characters\n", stderr);
            return 2;
        }
        size = file_size (argv[i + 1]);
        total_size += 8 + (uint64_t)size;
    }
    if (total_size > UINT32_MAX) {
        fputs ("ICNS output is too large\n", stderr);
        return 2;
    }

    output = fopen (argv[1], "wb");
    if (!output) {
        perror (argv[1]);
        return 1;
    }

    fwrite ("icns", 4, 1, output);
    write_u32 (output, (uint32_t)total_size);

    for (i = 2; i < argc; i += 2) {
        FILE *input;
        long size = file_size (argv[i + 1]);
        unsigned char buffer[16384];
        size_t count;

        fwrite (argv[i], 4, 1, output);
        write_u32 (output, (uint32_t)size + 8);

        input = fopen (argv[i + 1], "rb");
        if (!input) {
            perror (argv[i + 1]);
            return 1;
        }
        while ((count = fread (buffer, 1, sizeof (buffer), input)) > 0) {
            if (fwrite (buffer, 1, count, output) != count) {
                perror (argv[1]);
                return 1;
            }
        }
        fclose (input);
    }

    return fclose (output) == 0 ? 0 : 1;
}

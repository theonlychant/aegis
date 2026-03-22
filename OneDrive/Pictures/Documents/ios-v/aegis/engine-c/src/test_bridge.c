#include <stdio.h>
#include <string.h>
#include "aegis_ffi.h"

int main() {
    const char *h = aegis_hello();
    printf("aegis_hello: %s\n", h ? h : "<null>");

    const char *sample = "this contains malicious content";
    int r = aegis_scan_buffer_bridge((const unsigned char*)sample, strlen(sample));
    printf("aegis_scan_buffer_bridge returned: %d\n", r);
    const char *err = aegis_last_error();
    int code = aegis_last_error_code();
    if (err) {
        printf("last error code=%d msg=%s\n", code, err);
    } else {
        printf("no bridge error reported\n");
    }

    // Demonstrate wrapper
    int w = aegis_scan_buffer_checked((const unsigned char*)sample, strlen(sample));
    printf("aegis_scan_buffer_checked returned code: %d\n", w);

    return 0;
}

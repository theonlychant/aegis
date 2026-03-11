#include "aegis_ffi.h"
#include <string.h>

int aegis_scan_buffer_checked(const unsigned char *buf, unsigned long len) {
    if (!buf || len == 0) {
        aegis_set_last_error(AEGIS_ERR_NULL_ARG, "null or empty buffer");
        return AEGIS_ERR_NULL_ARG;
    }
    int res = aegis_scan_buffer_bridge(buf, len);
    if (res <= 0) {
        // map result to error
        aegis_set_last_error(AEGIS_ERR_INTERNAL, "scan failed or returned no matches");
        return AEGIS_ERR_INTERNAL;
    }
    return AEGIS_OK;
}

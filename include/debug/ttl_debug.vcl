sub ttl_debug {

	## I'm trying to understand why some images get low TTL
        # log ttl of the most used images. Here we can log only misses, because hits never arrived here
        if (bereq.url ~ "(?i)\.(jpeg|jpg|png|webp)(\?.*)?$" && beresp.ttl < 52w) {
                # from the backend, aka. miss
                std.log("IMAGE_TTL_BACKEND: " + bereq.url + " TTL=" + beresp.ttl);
                std.syslog(150, "IMAGE_TTL_BACKEND: " + bereq.url + " TTL=" + beresp.ttl);
        }

# This stub ends here
}

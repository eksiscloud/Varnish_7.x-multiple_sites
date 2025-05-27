sub match_config_attack {
    if (req.url ~ "^/(/wp\-admin/admin\-ajax\.php\\\?action\\=revslider_show_image\\\&img\\=\.\./wp\-config\.php|\^/cgi\-bin/config\.exp|\^/config/config\.ini|\^/config\.ini|/configuration.php.[1-9]|/configuration\.php\.backup|/configuration\.php\.old|\^/config/database\.yml|\^/config/databases\.yml|\^/deployment\-config\.json|\^/\\\.ftpconfig|/idx\-config|web\.config\.txt|\.well-known/autoconfig/mail/config-v1.1.xml|/wp\-config\-backup|/wp-config.php[1-9]|/wp-config[1-9]|/wp-config.[1-9]|/wp-config[1-9].txt|/wp\-config\.php\.backup|/wp\-config\-save|/wp_config\.php\.old|/wp\-configuration\.php_orig|/wp\-configuration\.php_original)") {
        if (req.http.X-County-Code ~ "fi" || req.http.X-Language ~ "fi") {
            return (synth(403, "Forbidden"));
        } else {
            return (synth(666, "Security issue"));
        }
    }
}
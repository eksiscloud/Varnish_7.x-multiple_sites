<?php
/**
 * WP CLI add-on
 *
 * Sends xkey-purge -request to purge whole domain from cache.
 *
 * Usage: wp varnish purge-domain <key>
 *
 * You must have defined domain-keys in Varnish
 */

if (!class_exists('WP_CLI')) {
    return;
}

WP_CLI::add_command('varnish purge-domain', function ($args) {
    if (empty($args[0])) {
        WP_CLI::error('Give domain-key (i.e. domain-example)');
    }

    $tag = sanitize_text_field($args[0]);
    $url = home_url('/');

    $response = wp_remote_request($url, [
        'method'  => 'BAN',
        'headers' => [
            'xkey-purge' => $tag,
            'X-Bypass'   => 'true', // if in use in VCL
        ],
        'timeout' => 5,
    ]);

    if (is_wp_error($response)) {
        WP_CLI::error('Error: ' . $response->get_error_message());
    }

    $code = wp_remote_retrieve_response_code($response);
    if ($code >= 200 && $code < 300) {
        WP_CLI::success("Sended: xkey-purge: $tag (answered HTTP $code)");
    } else {
        WP_CLI::warning("Request was sended, but the answer was $code");
    }
});

/**
in the root of domain, i.e. /var/www/domain/public_html/wp-cli.yml

```
require:
  - wp-content/purge-domain-command.php
```
*/

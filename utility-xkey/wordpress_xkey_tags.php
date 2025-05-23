// Add Xkey tags
// Use snippets plugin or functions.php

function add_xkey_cache_tags() {
    if (is_admin() || is_user_logged_in()) {
        return;
    }

    $tags = [];

    // FRONTPAGE
    if (is_front_page()) {
        $tags[] = 'frontpage';
    }

    // SINGLE ARTICLE
    if (is_single()) {
        global $post;
        if ($post && isset($post->ID)) {
            $tags[] = 'article-' . $post->ID;
        }
    }

    // CATEGORY
    if (is_category()) {
        $cat = get_queried_object();
        if ($cat && isset($cat->slug)) {
            $tags[] = 'category-' . sanitize_title($cat->slug);
        }
    }

    // SIDEBAR (right)
    $tags[] = 'sidebar';

    if (!headers_sent() && !empty($tags)) {
        header('X-Cache-Tags: ' . implode(',', $tags));
    }
}
add_action('send_headers', 'add_xkey_cache_tags');

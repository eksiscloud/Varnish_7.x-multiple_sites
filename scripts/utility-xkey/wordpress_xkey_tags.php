// Add  Xkey-based X-Cache-Tags headers
add_action('send_headers', function () {
    if (is_admin() || is_user_logged_in()) {
        return;
    }

    $tags = [];

    // Frontpage
    if (is_front_page()) {
        $tags[] = 'frontpage';
    }

    // Single post
    if (is_single()) {
        global $post;
        if ($post && isset($post->ID)) {
            $tags[] = 'article-' . $post->ID;

            // article-id
            $post_tags = get_the_tags($post->ID);
            if ($post_tags && !is_wp_error($post_tags)) {
                foreach ($post_tags as $tag) {
                    $tags[] = 'tag-' . sanitize_title($tag->slug);
                }
            }
        }
    }

    // Category archive
    if (is_category()) {
        $cat = get_queried_object();
        if ($cat && isset($cat->slug)) {
            $tags[] = 'category-' . sanitize_title($cat->slug);
        }
    }

    // Tag archive
    if (is_tag()) {
        $tag = get_queried_object();
        if ($tag && isset($tag->slug)) {
            $tags[] = 'tag-' . sanitize_title($tag->slug);
        }
    }

    // Sidebar on every page
    $tags[] = 'sidebar';

    // Domain (list every site here, just for easier copying; no, I'm not a skillful coder'
    if (!empty($_SERVER['HTTP_HOST'])) {
        if (strpos($_SERVER['HTTP_HOST'], 'poochierevival') !== false) {
            $tags[] = 'domain-poochie';
        } elseif (strpos($_SERVER['HTTP_HOST'], 'katiska') !== false) {
            $tags[] = 'domain-katiska';
        } elseif (strpos($_SERVER['HTTP_HOST'], 'eksis') !== false) {
            $tags[] = 'domain-eksis';
        } elseif (strpos($_SERVER['HTTP_HOST'], 'jagster') !== false) {
            $tags[] = 'domain-jagster';
        } elseif (strpos($_SERVER['HTTP_HOST'], 'dev') !== false) {
            $tags[] = 'domain-dev';
        }
    }

    // Add the header
    if (!headers_sent() && !empty($tags)) {
        header('X-Cache-Tags: ' . implode(',', array_unique($tags)));
    }
});

// Use snippers plugin or functions.php
// Adds xkey tags: frontpage, sidebar (right), article-ID, category and tag
// Remember to change url

add_action('save_post', function ($post_id) {
    // Don't do anything is this isn't an article or is autosaving
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) return;
    if (get_post_type($post_id) !== 'post') return;

    $tags = [];

    $tags[] = 'article-' . $post_id;
    $tags[] = 'sidebar';
    $tags[] = 'frontpage';

    // Categories
    $categories = get_the_category($post_id);
    if (!empty($categories)) {
        foreach ($categories as $cat) {
            $tags[] = 'category-' . sanitize_title($cat->slug);
        }
    }

    // Tags
    $post_tags = get_the_tags($post_id);
    if (!empty($post_tags)) {
        foreach ($post_tags as $tag) {
            $tags[] = 'tag-' . sanitize_title($tag->slug);
        }
    }

    $tags = array_unique($tags);

    foreach ($tags as $tag) {
        wp_remote_request(home_url('/'), [
            'method'  => 'BAN',
            'headers' => [
                'xkey-purge' => $tag
            ],
            'blocking' => false // not waiting for an answer
        ]);
    }
});

// Use snippers plugin or functions.php
// Adds xkey tags: frontpage, sidebar (right), article-ID, category
// Remember to change url

function run_xkey_purge_on_publish($post_id) {
    if (wp_is_post_revision($post_id) || wp_is_post_autosave($post_id)) {
        return;
    }

    $post = get_post($post_id);
    if ($post->post_status !== 'publish' || $post->post_type !== 'post') {
        return;
    }

    $tags = ['frontpage', 'sidebar', 'article-' . $post_id];
    $categories = get_the_category($post_id);
    foreach ($categories as $cat) {
        $tags[] = 'category-' . sanitize_title($cat->slug);
    }

    $tag_string = implode(',', $tags);
    $cmd = "curl -s -X PURGE -H 'xkey-purge: " . $tag_string . "' https://www.example.tld/ --http1.1";
    
    // Suoritetaan komento
    $output = shell_exec($cmd);
    
    // Lokitus tiedostoon
    $log_entry = date('[Y-m-d H:i:s]') . " PURGE sent for post ID {$post_id} with tags: {$tag_string}\n";
    $log_entry .= "Output: " . trim($output) . "\n\n";

    file_put_contents('/var/log/wordpress/xkey-purge.log', $log_entry, FILE_APPEND);
}
add_action('publish_post', 'run_xkey_purge_on_publish');
add_action('edit_post', 'run_xkey_purge_on_publish');

# Manual panicking, rarely needed anymore. I automated this. Check out /scripts

varnishd -I /etc/varnish/start.cli.emerg -P /var/run/varnish.pid \
  -j unix,user=vcache -F -a :8080 -T localhost:6082 -f "" \
  -S /etc/varnish/secret -s malloc,256M

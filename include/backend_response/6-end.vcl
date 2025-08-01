sub end-6 {

	### vcl_backend_response, last part

	## Unset Accept-Language, if backend gave one. I still want to keep it outside cache.
	unset beresp.http.Accept-Language;

	## Unset the old pragma header
	# Unnecessary filtering 'cos Varnish doesn't care of pragma, but it is ugly in headers
	# AFAIK WordPress doesn't use Pragma, so this is unnecessary here.
	unset beresp.http.Pragma;

# End of this sub
}

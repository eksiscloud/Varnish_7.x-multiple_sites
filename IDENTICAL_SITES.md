# Varnish VCL Deployment for Shared WordPress Sites

## Overview

This setup uses a shared VCL file (shared_wp.vcl) for multiple WordPress-based domains.
Each site has its own vcl.label but shares the same logic from one central VCL source.
This approach reduces duplication, simplifies updates, and ensures consistent behavior.


## 🗂️ Sites Using shared_wp.vcl

These sites all point to the same VCL file:
	•	/etc/varnish/sites/shared_wp.vcl

Labels are:
	•	katiska
	•	poochie
	•	jagster
	•	eksis
	•	selko
	•	dev

Each has its own vcl.label, e.g., katiska → katiska_20250529_1045.

## 🧱 Architecture Summary
	•	Each site uses its own vcl.label
	•	All labels share the same underlying file: shared_wp.vcl
	•	WordPress host normalization is done inside the shared file
	•	default.vcl routes traffic based on req.http.host → return(vcl(...))

## 🔒 Exception Sites

Some services do not use the shared configuration:
	•	store.katiska.eu (WooCommerce)
	•	stats.eksis.eu (Matomo)

These are defined separately in start.cli with their own vcl.load and vcl.label.


## 🧯 Legacy Script: vcl_deploy.sh

For historical purposes, there’s also a script that loads different VCL files per host.
This is not used under the current shared setup but may be kept for fallback scenarios.


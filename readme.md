# Collection of kubernetes manifests files for manual kubernetes deployment
* HPA configured as part of WMS (configuring HPA on other services requires testing, login session cookie stored in memory is lost when request is routed to different pod due to HPA, NGINX cookie affinity can be employed  but ideally an external session store is recommended)
* based on the 1.9.0 release of geoserver cloud
* anyone is welcomed to contribute to this project
* security context for each pod as non-root
* file system based, using NFS shares as PVs
* preparation for monitoring with prometheus/thanos 

job "haproxy" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

 group "ingress" {
    count = 3

    network {
      port "http" {
        static = 8080
      }

      port "haproxy_ui" {
        static = 1936
      }
    }

    service {
      name = "haproxy"
      port     = "http"
      check {
        name     = "port alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "haproxy" {
      driver = "docker"

      env {
        NOMAD_LOG_LEVEL = "INFO"
      }

      logs {
        max_files     = 10
        max_file_size = 10
      }

      config {
        image        = "haproxy:2.0"
        network_mode = "host"

        volumes = [
          "local/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg",
          "local/etag.lua:/etc/haproxy/etag.lua",
        ]
      }

      template {
        data = <<EOF
-- etag.lua
core.register_action("set_etag", { "http-res" }, function(txn)
    local etag_value = '"' .. core.sha1(os.time()) .. '"'
    txn.res:set_header("ETag", etag_value)
end)
EOF
        destination = "local/etag.lua"
      }     
      
      template {
        data = <<EOF
global
  lua-load /etc/haproxy/etag.lua
        
defaults
   mode http

frontend stats
   bind *:1936
   stats uri /
   stats show-legends
   no log

frontend http_front
   bind *:8080
   
   ### Stage 1: Match domain
   # Project ABCXYZ
   acl host_abcxyz  hdr(host) -i abcxyz.live.safebytelabs.dev
   # SBL CDN
   acl host_sbl_cdn hdr(host) -i    cdn.live.safebytelabs.dev
   # SBL dot DEV
   acl host_sbl_web hdr(host) -i    web.live.safebytelabs.dev
   acl host_sbl_web hdr(host) -i         www.safebytelabs.dev
   acl host_sbl_web hdr(host) -i             safebytelabs.dev



   ### Stage 2: Match specific path(s), if any. Be careful with potential overlaps
   acl path_prescriptions path_beg /prescriptions
   
   ### Stage 3: Match routing based on domain path(s)
   # Project ABCXYZ
   use_backend back_abcxyz_prescriptions if host_abcxyz path_prescriptions
   use_backend back_abcxyz if host_abcxyz !path_prescriptions        
   # SBL CDN
   use_backend back_sbl_cdn if host_sbl_cdn
   # SBL dot DEV
   use_backend back_sbl_web if host_sbl_web


backend back_abcxyz
    timeout client 10800s
    timeout server 10800s
    balance roundrobin
    server-template abcxyz-backend 1 _abcxyz-backend._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
    http-response del-header server
    http-response add-header server safebytelabs
    http-response lua.set_etag
        
backend back_abcxyz_prescriptions
    timeout client 10800s
    timeout server 10800s
    balance roundrobin
    server-template abcxyz-prescriptions 1 _abcxyz-prescriptions._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
    http-response del-header server
    http-response add-header server safebytelabs
    http-response lua.set_etag
        
backend back_sbl_web
    timeout client 10800s
    timeout server 10800s
    balance roundrobin
    server-template sbl-web 1 _nginx._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
    http-response del-header server
    http-response add-header server safebytelabs
    http-response lua.set_etag
        
backend back_sbl_cdn
    timeout client 10800s
    timeout server 10800s
    balance roundrobin
    server-template sbl-cdn 1 _nginx._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check
    http-response del-header server
    http-response add-header server safebytelabs
    http-response lua.set_etag
        
resolvers consul
    nameserver consul 127.0.0.1:8600
    accepted_payload_size 8192
    hold valid 5s
EOF

        destination = "local/haproxy.cfg"
      }

      resources {
        cpu    = 100
        memory = 100
      }
    }
  }
}

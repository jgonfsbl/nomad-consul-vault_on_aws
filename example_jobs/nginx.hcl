job "nginx" {
  datacenters = ["dc1"]

  
   group "web-servers" {
     count = 3
 
 
     network {
       port "http" { 
         to = 8888
       }
     }

     
   service {
     name = "nginx"
     port = "http"
     check {
       type     = "tcp"
       interval = "10s"
       timeout  = "2s"
     }
   }


   task "nginx" {
     driver = "docker"

     env {
       NOMAD_LOG_LEVEL = "INFO"
     }

     logs {
       max_files     = 10
       max_file_size = 10
     }
     
     config {
       image = "nginx:1.27.1-alpine"
       ports = ["http"]
       
       volumes = [ 
         "custom/default.conf:/etc/nginx/conf.d/default.conf",
         "/opt/efs/nginx:/opt/efs/nginx",
       ]
     }

     
     template {
       data = <<EOH
# Nginx server block that accepts to serve ANY domain and ANY subdomain
# (ensure DNS and TLS certificates are properly configured at ingress)
#
map $host $site_root {
    ~^(?<subdomain>.+)\.(?<domain>[^.]+)\.(?<tld>[^.]+)$ /opt/efs/nginx/$domain.$tld/$subdomain;
    ~^(?<domain>[^.]+)\.(?<tld>[^.]+)$ /opt/efs/nginx/$domain.$tld/html;
}

server {
    listen 8888;
    server_name _;

    root $site_root;

    location / {
        index index.html;
        try_files $uri $uri/ /index.html =404;
    }

    # Error handling
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
}
#
# EOF
EOH    
       destination = "custom/default.conf"
     }
  

     resources {
       cpu = 100 
       memory = 100
     }
     
    }
   }
  }

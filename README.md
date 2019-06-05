# Elasticsearch+Kibana as digital archeology tool


## Install and start ES+Kibana
Need 2G RAM (i use START1-S in scaleway.com). 
```bash
apt update && apt install git -y 
git clone https://github.com/vvzvlad/es_digital_archeology.git && cd es_digital_archeology
make docker start  
```
Open port 80, and use kibana:kibana_password for open kibana panel. Change port and login/pass in docker-compose.yml file:

```
  nginx-kibana:
    image: beevelop/nginx-basic-auth
    container_name: nginx-kibana-auth
    depends_on:
      - kibana
    environment:
      - HTPASSWD=kibana:{PLAIN}kibana_password
#         Login ---^                 ^---Password
      - FORWARD_PORT=5601
    networks:
      - elastic
    ports:
      - 80:80
#          ^----Web-panel port
    links:
      - kibana:web
```
Run "make docker-daemon" for daemonize and auto-start server.


## Run LJ-crawler
Install perl libs:
```
make perl 
```

Run crawler:
```
perl lj-user-crawler.pl haritonov -y 2001-2019 -m 1-12
```

Crawler based on https://github.com/roman-lugovkin/lj-crawler

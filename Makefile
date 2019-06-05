
all: perl docker

perl:
	apt-get install -y libwww-perl libjson-perl

docker: set_vm_memory install_docker install_docker_compose

install_docker:
	wget -q -O - https://get.docker.com | sh

install_docker_compose:
	curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose

set_vm_memory:
	sysctl -w vm.max_map_count=262144
	echo "vm.max_map_count=262144" >> /etc/sysctl.conf

start:
	/usr/local/bin/docker-compose up

start-daemon:
	/usr/local/bin/docker-compose up -d

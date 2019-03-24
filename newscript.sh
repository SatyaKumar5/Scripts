#!/bin/bash
########################################################################
# install kafka with dependencies
########################################################################
sudo apt-get update
sudo apt-get install default-jre
sudo wget http://apache.osuosl.org/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz
apt-get install zookeeperd -y
sudo adduser --system --no-create-home --disabled-password --disabled-login kafka
wget https://www-us.apache.org/dist/kafka/0.10.2.2/kafka_2.12-0.10.2.2.tgz
#curl http://kafka.apache.org/KEYS | gpg --import
#wget https://dist.apache.org/repos/dist/release/kafka/1.0.0/kafka_2.11-1.0.0.tgz.asc
#gpg --verify kafka_2.11-1.0.0.tgz.asc kafka_2.11-1.0.0.tgz
sudo mkdir /opt/kafka
sudo tar -xvzf kafka_2.12-0.10.2.2.tgz --directory /opt/kafka --strip-components 1
rm kafka_2.12-0.10.2.2.tgz kafka_2.12-0.10.2.2.tgz.asc
sudo nano /opt/kafka/config/server.properties
sudo chown -R kafka:nogroup /opt/kafka
########################################################################
# Attention: depends on the environment
# SIGTERM may or may not be OK (SuccessExitStatus=143)
########################################################################
sudo tee /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=High-available, distributed message broker
Requires=network.target remote-fs.target
After=network.target remote-fs.target
[Service]
Type=simple
User=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
SuccessExitStatus=143
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable kafka.service
sudo systemctl start kafka


wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | 
sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo apt-get update && sudo apt-get install elasticsearch

sudo service elasticsearch start
sudo apt-get install kibana

sudo sed -i '$ a server.port: 5601\nelasticsearch.url: "http://localhost:9200"\nserver.host: "0.0.0.0"' sudo /etc/kibana/kibana.yml

sudo service kibana start
sudo apt install filebeat


sudo tee /etc/filebeat/modules.d/kafka.yml.disabled <<EOF
- module: kafka
  # All logs
  log:
    enabled: true
    # Set custom paths for Kafka. If left empty,
    # Filebeat will look under /opt.
    #var.kafka_home:
    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    var.paths:
     - "/opt/kafka/logs/server.log"
    # Convert the timestamp to UTC. Requires Elasticsearch >= 6.1.
    #var.convert_timezone: false
EOF


sudo filebeat modules enable kafka
sudo filebeat setup -e
sudo service filebeat restart

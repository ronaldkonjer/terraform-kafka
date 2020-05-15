#!/usr/bin/env bash
set -ex
# Script to setup a Kafka server

# unload the command line
broker_id=$1
az=$2

# update java
sudo yum remove -y java-1.7.0-openjdk
sudo yum install -y java-1.8.0

# add directories that support kafka
mkdir -p /opt/kafka
mkdir -p /var/run/kafka
mkdir -p /var/log/kafka

# download kafka
base_name=kafka_${scala_version}-${version}
cd /tmp
curl -L ${repo}/${version}/$base_name.tgz -o $base_name.tgz

# unpack the tarball
cd /opt/kafka
tar xzf /tmp/$base_name.tgz
rm /tmp/$base_name.tgz
cd $base_name

# configure the server
cat config/server.properties \
    | sed "s|broker.id=0|broker.id=$broker_id|" \
   # | sed 's|advertised.listeners=PLAINTEXT://:9092|advertised.listeners=PLAINTEXT://ec2-18-132-90-74.eu-west-2.compute.amazonaws.com:9092|' \
    | sed 's|log.dirs=/tmp/kafka-logs|log.dirs=${mount_point}/kafka-logs|' \
    | sed 's|num.partitions=1|num.partitions=${num_partitions}|' \
    | sed 's|log.retention.hours=168|log.retention.hours=${log_retention}|' \
    | sed 's|zookeeper.connect=localhost:2181|zookeeper.connect=${zookeeper_connect}|' \
    > /tmp/server.properties
echo >> /tmp/server.properties
echo "# rack ID" >> /tmp/server.properties
echo "broker.rack=$az" >> /tmp/server.properties
echo " " >> /tmp/server.properties
echo "# replication factor" >> /tmp/server.properties
echo "default.replication.factor=${repl_factor}" >> /tmp/server.properties
echo "delete.topic.enable = true" >> /tmp/server.properties
mv /tmp/server.properties config/server.properties

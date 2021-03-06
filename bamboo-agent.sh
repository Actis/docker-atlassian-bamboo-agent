#!/bin/bash

cd /root 

if [ -z "${BAMBOO_SERVER}" ]; then
	echo "Bamboo server URL undefined!" >&2
	echo "Please set BAMBOO_SERVER environment variable to URL of your Bamboo instance." >&2
	exit 1
fi

BAMBOO_AGENT=atlassian-bamboo-agent-installer.jar

if [ -z "${BAMBOO_AGENT_HOME}" ]; then
	export BAMBOO_AGENT_HOME=/var/lib/bamboo
fi

if [ ! -f ${BAMBOO_AGENT} ]; then
	echo "Downloading agent JAR..."
	wget "-O${BAMBOO_AGENT}" "${BAMBOO_SERVER}/agentServer/agentInstaller/${BAMBOO_AGENT}"
fi

if [ ! -d ${BAMBOO_AGENT_HOME}/bin ]; then
	mkdir -p ${BAMBOO_AGENT_HOME}/bin
fi

cp bamboo-capabilities.properties ${BAMBOO_AGENT_HOME}/bin/

docker_version=`docker --version | sed -e "s/Docker version \(.*\), build .*/\1/"`
compose_version=`docker-compose --version | sed -e "s/docker\-compose version \(.*\), build .*/\1/"`
kubectl_version=`kubectl version --short --client | sed -e "s/^Client Version: v\(.*\)$/\1/"`

sed -i -E "s/docker\.version=.*/docker\.version=$docker_version/" ${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties
sed -i -E "s/docker\-compose\.version=.*/docker\-compose\.version=$compose_version/" ${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties
sed -i -E "s/kubectl\.version=.*/kubectl\.version=$kubectl_version/" ${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties

if [ ! -f ${BAMBOO_AGENT_HOME}/bamboo-agent.cfg.xml -a "${BAMBOO_AGENT_UUID}" != "" ]; then
	echo 'agentUuid='${BAMBOO_AGENT_UUID} >> ${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties
fi

if [ ! -f ${BAMBOO_AGENT_HOME}/bamboo-agent.cfg.xml -a "${BAMBOO_AGENT_CAPABILITY}" != "" ]; then
	echo ${BAMBOO_AGENT_CAPABILITY} >> ${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties
fi

echo "Setting up the environment..."
export LANG=en_US.UTF-8
export JAVA_TOOL_OPTIONS="-Dfile.encoding=utf-8 -Dsun.jnu.encoding=utf-8"

echo Starting Bamboo Agent...
java -Dbamboo.home=${BAMBOO_AGENT_HOME} -jar "${BAMBOO_AGENT}" "${BAMBOO_SERVER}/agentServer/"

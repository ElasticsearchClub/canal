#!/bin/bash 

current_path=`pwd`
case "`uname`" in
    Linux)
		bin_abs_path=$(readlink -f $(dirname $0))
		;;
	*)
		bin_abs_path=`cd $(dirname $0); pwd`
		;;
esac
base=${bin_abs_path}/..
canal_conf=$base/conf/canal.properties
canal_local_conf=$base/conf/canal_local.properties
logback_configurationFile=$base/conf/logback.xml
export LANG=en_US.UTF-8
export BASE=$base

if [ -f $base/bin/canal.pid ] ; then
	echo "found canal.pid , Please run stop.sh first ,then startup.sh" 2>&2
    exit 1
fi

if [ ! -d $base/logs/canal ] ; then 
	mkdir -p $base/logs/canal
fi

## set java path
if [ -z "$JAVA" ] ; then
  JAVA=$(which java)
fi

ALIBABA_JAVA="/usr/alibaba/java/bin/java"
TAOBAO_JAVA="/opt/taobao/java/bin/java"
if [ -z "$JAVA" ]; then
  if [ -f $ALIBABA_JAVA ] ; then
  	JAVA=$ALIBABA_JAVA
  elif [ -f $TAOBAO_JAVA ] ; then
  	JAVA=$TAOBAO_JAVA
  else
  	echo "Cannot find a Java JDK. Please set either set JAVA or put java (>=1.5) in your PATH." 2>&2
    exit 1
  fi
fi

case "$#" 
in
0 ) 
	;;
1 )	
	var=$*
	if [ "$var" = "local" ]; then
		canal_conf=$canal_local_conf
	else
		if [ -f $var ] ; then 
			canal_conf=$var
		else
			echo "THE PARAMETER IS NOT CORRECT.PLEASE CHECK AGAIN."
			exit
		fi
	fi;;
2 )	
	var=$1
	if [ "$var" = "local" ]; then
		canal_conf=$canal_local_conf
	else
		if [ -f $var ] ; then
			canal_conf=$var
		else 
			if [ "$1" = "debug" ]; then
				DEBUG_PORT=$2
				DEBUG_SUSPEND="n"
				JAVA_DEBUG_OPT="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=$DEBUG_SUSPEND"
			fi
		fi
     fi;;
* )
	echo "THE PARAMETERS MUST BE TWO OR LESS.PLEASE CHECK AGAIN."
	exit;;
esac

str=`file -L $JAVA | grep 64-bit`
if [ -n "$str" ]; then
	JAVA_OPTS="-server  -Xmx4g  -Xms4g  -XX:MetaspaceSize=256m  -XX:MaxMetaspaceSize=256m    -Xss256k  -XX:MaxDirectMemorySize=4g  -XX:+UseG1GC  -XX:+UnlockExperimentalVMOptions  -XX:MaxGCPauseMillis=100  -XX:G1NewSizePercent=2  -XX:InitiatingHeapOccupancyPercent=65  -XX:+ParallelRefProcEnabled  -XX:ConcGCThreads=2  -XX:ParallelGCThreads=8  -XX:MaxTenuringThreshold=1  -XX:G1HeapRegionSize=32m  -XX:G1MixedGCCountTarget=64  -XX:G1OldCSetRegionThresholdPercent=5  -XX:+HeapDumpOnOutOfMemoryError  -verbose:gc  -XX:+PrintGC  -XX:+PrintGCDetails  -XX:+PrintGCApplicationStoppedTime  -XX:+PrintHeapAtGC  -XX:+PrintGCDateStamps  -XX:+PrintGCTimeStamps  -XX:+PrintAdaptiveSizePolicy  -XX:+PrintTenuringDistribution  -XX:+PrintSafepointStatistics  -XX:PrintSafepointStatisticsCount=1  -XX:PrintFLSStatistics=1  -XX:+PrintClassHistogram  -XX:+PrintReferenceGC  -XX:ErrorFile=/data/error/canal/canal-deployer-1.1.5_quick-search/hs_err_pid%p.log  -Xloggc:/data/gc/canal/canal-deployer-1.1.5_quick-search/gc_%p.log  -XX:+UseGCLogFileRotation  -XX:NumberOfGCLogFiles=32  -XX:GCLogFileSize=64m  -Des.networkaddress.cache.ttl=60  -Des.networkaddress.cache.negative.ttl=10  -XX:+AlwaysPreTouch  -Djava.awt.headless=true  -Dfile.encoding=UTF-8  -Djna.nosys=true  -XX:-OmitStackTraceInFastThrow"
else
	JAVA_OPTS="-server  -Xmx4g  -Xms4g  -XX:MetaspaceSize=256m  -XX:MaxMetaspaceSize=256m    -Xss256k  -XX:MaxDirectMemorySize=4g  -XX:+UseG1GC  -XX:+UnlockExperimentalVMOptions  -XX:MaxGCPauseMillis=100  -XX:G1NewSizePercent=2  -XX:InitiatingHeapOccupancyPercent=65  -XX:+ParallelRefProcEnabled  -XX:ConcGCThreads=2  -XX:ParallelGCThreads=8  -XX:MaxTenuringThreshold=1  -XX:G1HeapRegionSize=32m  -XX:G1MixedGCCountTarget=64  -XX:G1OldCSetRegionThresholdPercent=5  -XX:+HeapDumpOnOutOfMemoryError  -verbose:gc  -XX:+PrintGC  -XX:+PrintGCDetails  -XX:+PrintGCApplicationStoppedTime  -XX:+PrintHeapAtGC  -XX:+PrintGCDateStamps  -XX:+PrintGCTimeStamps  -XX:+PrintAdaptiveSizePolicy  -XX:+PrintTenuringDistribution  -XX:+PrintSafepointStatistics  -XX:PrintSafepointStatisticsCount=1  -XX:PrintFLSStatistics=1  -XX:+PrintClassHistogram  -XX:+PrintReferenceGC  -XX:ErrorFile=/data/error/canal/canal-deployer-1.1.5_quick-search/hs_err_pid%p.log  -Xloggc:/data/gc/canal/canal-deployer-1.1.5_quick-search/gc_%p.log  -XX:+UseGCLogFileRotation  -XX:NumberOfGCLogFiles=32  -XX:GCLogFileSize=64m  -Des.networkaddress.cache.ttl=60  -Des.networkaddress.cache.negative.ttl=10  -XX:+AlwaysPreTouch  -Djava.awt.headless=true  -Dfile.encoding=UTF-8  -Djna.nosys=true  -XX:-OmitStackTraceInFastThrow"
fi

JAVA_OPTS=" $JAVA_OPTS -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8"
CANAL_OPTS="-DappName=otter-canal -Dlogback.configurationFile=$logback_configurationFile -Dcanal.conf=$canal_conf"

if [ -e $canal_conf -a -e $logback_configurationFile ]
then 
	
	for i in $base/lib/*;
		do CLASSPATH=$i:"$CLASSPATH";
	done
 	CLASSPATH="$base/conf:$CLASSPATH";
 	
 	echo "cd to $bin_abs_path for workaround relative path"
  	cd $bin_abs_path
 	
	echo LOG CONFIGURATION : $logback_configurationFile
	echo canal conf : $canal_conf 
	echo CLASSPATH :$CLASSPATH
	$JAVA $JAVA_OPTS $JAVA_DEBUG_OPT $CANAL_OPTS -classpath .:$CLASSPATH com.alibaba.otter.canal.deployer.CanalLauncher 1>>$base/logs/canal/canal_stdout.log 2>&1 &
	echo $! > $base/bin/canal.pid 
	
	echo "cd to $current_path for continue"
  	cd $current_path
else 
	echo "canal conf("$canal_conf") OR log configration file($logback_configurationFile) is not exist,please create then first!"
fi

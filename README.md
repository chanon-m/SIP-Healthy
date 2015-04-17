# SIP-Healthy
SIP Service Monitoring

![Alt text](http://www.icalleasy.com/images/sip_healthy.png "Basic VOIP System") 
 
#Licensing Information: READ LICENSE

#Project source can be downloaded from
##https://github.com/chanon-m/sip-healthy.git

#Author & Contributor

Chanon Mingsuwan

Reported bugs or requested new feature can be sent to chanonm@live.com

#How to run a file
* Download files in your remote server

```

# git clone https://github.com/chanon-m/sip-healthy.git

```

* Copy sip_healthy.pl and call_quality_report.pl to /usr/lib/check_mk_agent/local/300

```

# cp ./sip-healthy/sip_healthy.pl /usr/lib/check_mk_agent/local/300
# cp ./sip-healthy/call_quality_report.pl /usr/lib/check_mk_agent/local/300

```

* Make a file executable

```

# chmod 755 /usr/lib/check_mk_agent/local/300/sip_healthy.pl
# chmod 755 /usr/lib/check_mk_agent/local/300/call_quality_report.pl

```

* Download files in your server

```

# git clone https://github.com/chanon-m/sip-healthy.git

```

* Copy call_quality_srv.pl to /etc

```

# cp ./sip-healthy/call_quality_srv.pl /etc

```

* Make a file executable

```

# chmod 755 /etc/call_quality_srv.pl

```

* Run call_quality_srv.pl as server in your server

```

# ./etc/call_quality_srv.pl [local SIP Server IP address] [port number]

```

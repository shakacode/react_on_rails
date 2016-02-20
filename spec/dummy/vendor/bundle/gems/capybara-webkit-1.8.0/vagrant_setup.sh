#!/bin/bash

export DISPLAY=:99

apt-get -y update
apt-get -y install ruby1.9.1-dev

if [ -z `which make` ]; then apt-get -y install build-essential; fi
if [ -z `which qmake` ]; then apt-get -y install libqt4-dev libicu48; fi
if [ -z `which git` ]; then apt-get -y install git-core; fi
if [ -z `which xml2-config` ]; then apt-get -y install libxml2-dev; fi
if [ -z `which xslt-config` ]; then apt-get -y install libxslt-dev; fi
if [ -z `which convert` ]; then apt-get -y install imagemagick; fi
if [ -z `which firefox` ]; then apt-get -y install firefox; fi

if [ -z `which bundle` ];
then
  gem install bundler
  cd /vagrant
  bundle
fi

if [ ! -f /etc/init.d/xvfb ];
then
  apt-get -y install xvfb
  echo "export DISPLAY=${DISPLAY}" >> /home/vagrant/.bashrc
  tee /etc/init.d/xvfb <<-EOF
    #!/bin/bash

    XVFB=/usr/bin/Xvfb
    XVFBARGS="\$DISPLAY -ac -screen 0 1024x768x16"
    PIDFILE=\${HOME}/xvfb_\${DISPLAY:1}.pid
    case "\$1" in
      start)
        echo -n "Starting virtual X frame buffer: Xvfb"
        /sbin/start-stop-daemon --start --quiet --pidfile \$PIDFILE --make-pidfile --background --exec \$XVFB -- \$XVFBARGS
        echo "."
        ;;
      stop)
        echo -n "Stopping virtual X frame buffer: Xvfb"
        /sbin/start-stop-daemon --stop --quiet --pidfile \$PIDFILE
        echo "."
        ;;
      restart)
        \$0 stop
        \$0 start
        ;;
      *)
        echo "Usage: /etc/init.d/xvfb {start|stop|restart}"
        exit 1
    esac
    exit 0
EOF

  chmod +x /etc/init.d/xvfb
fi

/etc/init.d/xvfb start

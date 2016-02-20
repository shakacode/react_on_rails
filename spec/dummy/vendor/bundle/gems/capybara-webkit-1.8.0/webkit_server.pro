TEMPLATE = subdirs
CONFIG += ordered
SUBDIRS += src/webkit_server.pro
test {
  SUBDIRS += test/testwebkitserver.pro
}

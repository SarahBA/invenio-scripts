# set default path if none is set (in invenio-scripts)
if [ "$INVENIO_DIR" = "" ] && [ "$1" = "" ]; then
   INVENIO_DIR="/opt/invenio"
elif [ "$1" != "" ]; then
   INVENIO_DIR="$1"
fi
sudo -u www-data $INVENIO_DIR/bin/bibindex -f50000 -s5m -uadmin
sudo -u www-data $INVENIO_DIR/bin/bibreformat -oHB -s5m -uadmin
sudo -u www-data $INVENIO_DIR/bin/webcoll -v0 -s5m -uadmin
sudo -u www-data $INVENIO_DIR/bin/bibrank -f50000 -s5m -uadmin
sudo -u www-data $INVENIO_DIR/bin/bibsort -s5m -uadmin

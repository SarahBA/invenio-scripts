sudo -u www-data /opt/invenio/bin/bibindex -f50000 -s5m -uadmin
sudo -u www-data /opt/invenio/bin/bibreformat -oHB -s5m -uadmin
sudo -u www-data /opt/invenio/bin/webcoll -v0 -s5m -uadmin
sudo -u www-data /opt/invenio/bin/bibrank -f50000 -s5m -uadmin
sudo -u www-data /opt/invenio/bin/bibsort -s5m -uadmin

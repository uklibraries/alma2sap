alma2sap
========

This includes the service runner and report mailer for alma2sap, a system for
converting Alma invoice XML files to SAP IDoc data files suitable for invoice
payment.
It is geared specifically to the needs of users at the 
[University of Kentucky Libraries](https://libraries.uky.edu).

Additional packages required:

* [alma2sap-reader](https://github.com/uklibraries/alma2sap-reader)
* [alma2sap-submitter](https://github.com/uklibraries/alma2sap-submitter)

The packages should be installed in reader/service and submitter/service
respectively.

The file alma2sap.sh specifies a number of directories (inbox, todo, and so on)
which need to exist in the reader and submitter directories.  You will need
to ensure these directories (or appropriate symlinks) exist.

You will need to rename mail.pl.example to mail.pl and add the email addresses
of users who need to receive reports.

Finally, you will also need to add an appropriate cron job for the service
runner:

```
30 20 * * * bash /path/to/alma2sap.sh
```

The scripts in this package are in the public domain.  See LICENSE for details.

Brief overview:

* [https://scdp.uky.edu/mps/talks/2017-01-12/alma2sap/#/](https://scdp.uky.edu/mps/talks/2017-01-12/alma2sap/#/)

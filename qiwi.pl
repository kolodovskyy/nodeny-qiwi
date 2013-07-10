#!/usr/bin/perl
# by Yuriy Kolodovskyy aka Lexx
# lexx@ukrindex.com
# +380445924814
# common version
# @version 20120608

use Time::localtime;
use Time::Local;
use MIME::Base64;
use DBI;
use CGI;

# CONFIG: pay category (97 by default)
$category=97;

$main_config = '/usr/local/nodeny/nodeny.cfg.pl';
$call_pl = "/usr/local/nodeny/web/calls.pl";
$log_file='/usr/local/nodeny/module/qiwi.log';

sub Log
{
    my ($time);
    open LOG, ">>$log_file";
    $time = CORE::localtime;
    print LOG "$time: $_[0]\n";
    close LOG;
}

sub Ret
{
    $txn_id = 0 if !$txn_id;
    &Log($_[1]) if $_[1];
    print "Content-type: text/xml\n\n";
    print "<?xml version=\"1.0\" ?> \n";
    print "<response>\n";
    print "\t<osmp_txn_id>$txn_id</osmp_txn_id>\n";
    print "\t<result>$_[0]</result>\n";
    print "</response>\n";
    exit;
}

$cgi=new CGI;

$txn_id = $cgi->param('txn_id');
&Ret(300, 'Wrong txn_id: ' . $txn_id) unless ($txn_id=~/^\d{1,20}$/);
$command = $cgi->param('command');
&Ret(300, 'Wrong command: ' . $command) unless ($command eq 'check' || $command eq 'pay');
$sum = $cgi->param('sum');
&Ret(300, 'Wrong sum: ' . $sum) unless ($command eq 'check' || ($command eq 'pay' && $sum=~/^\d{1,6}\.\d{1,2}$/));
$date = $cgi->param('txn_date');
if ($command ne 'check') {
    &Ret(300, 'Wrong date: ' . $date) unless $date=~/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/;
    $date = "$1-$2-$3 $4:$5:$6";
}

$account = $cgi->param('account');
&Ret(4, 'Wrong account') unless ($account=~/^\d+$/);
$sum1 = $account % 10;
$account = int($account / 10);
$sum2=0;
$sum2+=$_ foreach split //, $account;
$sum2%=10;
&Ret(4, 'Hashsum error for account: ' . $account) if $sum1!=$sum2;

&Ret(1, 'Main config not found') unless -e $main_config;
require $main_config;
&Ret(1, 'Call.pl not found') unless -e $call_pl;
require $call_pl;

$dbh=DBI->connect("DBI:mysql:database=$db_name;host=$db_server;mysql_connect_timeout=$mysql_connect_timeout;",
          $user,$pw,{PrintError=>1});
&Ret(1, 'Could not connect to database') unless $dbh;
$dbh->do('SET NAMES UTF8');

$p=&sql_select_line($dbh,"SELECT * FROM users WHERE id='$account' AND mid='0'");
&Ret(5, 'Account not found: ' . $account) unless $p;
&Ret(0, 'Account exist: ' . $account) if $command eq 'check';

&Ret(0, 'Pay already exist with txn_id: ' . $txn_id)
    if &sql_select_line($dbh, "SELECT * FROM pays WHERE category='$category' AND reason='$txn_id'");

$sum_ok = $sum > 0 ? 1 : 0;

$sum_ok && $dbh->do("INSERT INTO pays SET 
    mid='$mid',
    cash='$sum',
    time=UNIX_TIMESTAMP('$date'),
    admin_id=0,
    admin_ip=0,
    office=0,
    bonus='y',
    reason='$txn_id',
    coment='QIWI ($txn_id)',
    type=10,
    category=$category");
$sum_ok && $dbh->do("UPDATE users SET state='on', balance=balance+$sum WHERE id='$mid'");
$sum_ok && $dbh->do("UPDATE users SET state='on' WHERE mid='$mid'");

&Ret(0, "Pay added to billing account:$account txn_id:$txn_id date:$date sum:$sum" . ($sum_ok ? '' : " (WANRING: sum is 0)"));

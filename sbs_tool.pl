#!/apollo/env/envImprovement/bin/perl
use strict;
use Getopt::Long;

my $run_date        = undef;
my $org             = undef;
my $help            = undef;
my $newjar          = undef;
my $oldjar          = undef;
my $pswd            = undef;
my $SBS_HOST        = undef;
my $type            = undef;
my $jar             = undef;
my $job_name        = undef;
my $tag             = "default";
my $nodelete        = undef;
my $source          = undef;
my $realm           = undef;
my $cfg             = undef;

GetOptions(
    'cfg=s'         => \$cfg,
    'nodelete'      => \$nodelete,
    'tag=s'         => \$tag,
    'rundate=s'     => \$run_date,
    'org=s'         => \$org,
    'type=s'        => \$type,
    'jar=s'         => \$jar,
    'newjar=s'      => \$newjar,
    'oldjar=s'      => \$oldjar,
    'pswd=s'        => \$pswd,
    'source=s'      => \$source,
    'realm=s'       => \$realm,
    'help|?'        => \$help,
) or die "canot parse command line options.";

my $domain = 'prod';
my $root = '/apollo/env/Prioritization';
my $config = '/apollo/env/Prioritization/brazil-config/override/Priority.cfg';
my $job_config = undef;

if ($help) {
    printUsage();
    exit(0);
}

#
# print usage
# 
sub printUsage {
    print <<EOF
    Usage: sbs_tool.pl
                [--run-date=<run date>]
                    date in format YYYY-MM-DD
                [--org=<org>]
                    org must be upper case, such as CN, GB, DE and etc.
                [--tag=<tag>]
                [--type=<type>]
                    --type once/twice
                [--jar=<HadoopJobEngine.jar>]
                [--newjar=<HadoopJobEngine.jar>]
                [--oldjar=<HadoopJobEngine.jar>]
                [--nodelete]
                [--source=<source>]
                    You can provide one source or mutiple sources seperated by comma,
                    For example --source OIH, 
                                --source OIH,CBM 
                    Currently, there are only two kinds of source ,OIH and CBM.
                [--pswd=<password>]
                [--realm=<realm>]
                [--help]

            Example:

            /apollo/env/OihToolbox/bin/analysis_tools/sbs_tool.pl --org CN --rundate 2014-04-15 --type once 
EOF
;
}
 
my $ret = undef;
if(!defined($pswd))
{
    print "Please enter your password : ";
    system('stty','-echo');
    chop($pswd =<STDIN>);
    system('stty','echo');
    $ret = system("echo $pswd | sudo -k -S echo ' '");
    while($ret != 0){
        print "Your password is wrong,please re-enter your password : ";
        system('stty','-echo');
        chop($pswd =<STDIN>);
        system('stty','echo');
        $ret = system("echo $pswd | sudo -k -S echo ' '");
    }
}

if (!defined($run_date)){
    die "you must specify option --rundate YYYY-MM-DD";
}
print "ORG $org\n";
print "rundate $run_date\n";
my $date7 = `date +%F -d \"\$(date +%F -d $run_date) -7 day\"`;
my $date8 = `date +%F -d \"\$(date +%F -d $run_date) -8 day\"`;
my $date1 = `date +%F -d \"\$(date +%F -d $run_date) -1 day\"`;
my $date0 = $run_date;
chomp $date7;
chomp $date0;
chomp $date8;
chomp $date1;

if (!defined($org)){
    die "you must specify option --org XX";
}

if(!defined($realm)){
    $realm = $org.'Amazon';
}

$job_name = $realm."OihCalculation";
my $env = undef;
if ($org eq "US"){

    $env ="
	export TZ=US/Pacific;
	export OIH_NFS=scos-oih-nfs-na-1101.vdc.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=US;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=USAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=us-hq;
    ";
    $SBS_HOST = "ops-new-launch-7236.iad7.amazon.com";
}

if ($org eq "CA"){
    $env = "
	export TZ=US/Pacific;
	export OIH_NFS=scos-oih-nfs-na-1101.vdc.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=CA;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=CAAmazon;
	export AMAZON_ENVIRONMENT=ca-hq;
	export ROOT=/apollo/env/Prioritization;
    ";
    $SBS_HOST = "ops-new-launch-7237.iad7.amazon.com";
}


if ($org eq "EU"){
    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-na-1101.vdc.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=EU;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=EUAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=gb-hq;
    ";
    $SBS_HOST = undef;
}

if ($org eq "GB"){

    $env = "
	export TZ=Europe/London;
	export OIH_NFS=scos-oih-nfs-na-1101.vdc.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=GB;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=GBAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=gb-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12012.dub2.amazon.com";
}

if ($org eq "DE"){

    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=DE;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=DEAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=de-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12002.dub2.amazon.com";
}


if ($org eq "FR"){

    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=FR;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=FRAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=fr-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12004.dub2.amazon.com";
}


if ($org eq "IT"){

    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=IT;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=ITAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=it-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12002.dub2.amazon.com";
}


if ($org eq "ES"){

    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=ES;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=ESAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=es-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12002.dub2.amazon.com";
}


if ($org eq "JP"){

    $env = "
	export TZ=Europe/London;
	export OIH_NFS=scos-oih-nfs-fe-4102.sea5.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=JP;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=JPAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=jp-hq;
    ";
    $SBS_HOST = "scos-oih-fe-31003.sea31.amazon.com";
}


if ($org eq "CN"){

    $env = "
	export TZ=Asia/Shanghai;
    export IOG=71;
	export OIH_NFS=scos-oih-cn-34003.pek4.amazon.com;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=CN;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=CNAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=cn-hq;
    ";
    $SBS_HOST = "scos-oih-cn-34003.pek4.amazon.com";
}

if ($org eq "IN"){

    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=IN;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=INAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=in-hq;
    ";
    $SBS_HOST = "scos-oih-eu-12004.dub2.amazon.com";
}

if ($org eq "BR"){
    $env = "
	export TZ=Europe/Berlin;
	export OIH_NFS=scos-oih-nfs-eu-12001.dub2;
	export ORACLE_HOME=/opt/app/oracle/product/10.2.0.2/client;
	export LD_LIBRARY_PATH=/apollo/env/Prioritization/lib;
	export ORG=BR;
	export PATH=\\\${PATH}:/opt/third-party/bin;
	export DOMAIN=prod;
	export REALM=BRAmazon;
	export ROOT=/apollo/env/Prioritization;
	export AMAZON_ENVIRONMENT=br-hq;
    ";
    $SBS_HOST = undef;
}

my $user = $ENV{'USER'};

my $output_dir = "$root/var/output/data/$domain/$realm/$user";
my $output_dir_cmd = "
if [ ! -d \\\"$output_dir\\\" ];then 
    mkdir $output_dir
    chmod 777 $output_dir
fi
";
system("ssh $SBS_HOST \"$output_dir_cmd\"");
$output_dir .= "/$tag";
system("ssh $SBS_HOST \"mkdir $output_dir && chmod 777 $output_dir\"");

my $sbs_space = "/home/$user/sbs_space";
my $override_dir = "$sbs_space/local-overrides";
my $override_cfg = "$override_dir/Priority.cfg";

sub hadoop_run {
    
    print "*****************************************************************************************************************************\n\n";
    print "Hadoop Job OihCalculation is starting...\n\n";
    print "*****************************************************************************************************************************\n\n";
    my $cmd="$env echo $pswd | sudo -u ihradmin -S /apollo/env/OihHadoop/bin/apollo-hadoop "; 
    my $main_class;

    $job_config = "$override_dir/OihCalculation.xml";
    if($jar){
        system("scp $jar $SBS_HOST\:$override_dir/$jar");
        $main_class = "com.amazon.oih.hadoop.MyJobBootStrap";
        $cmd .= "jar $override_dir/$jar $main_class ";
    }else{
        $jar = "/apollo/env/Prioritization/lib/HadoopJobEngineInterface-1.0.jar";
        $main_class = "com.amazon.oih.hadoop.JobBootStrap";
        $cmd .= "jar $jar $main_class ";
    }

    $cmd .= " --confFile $job_config --realm $realm --rundate $run_date --jobName $job_name --domain $domain --root $root --appgroup Oih --start-date $date7 --end-date $date0 --appname OihMetrics --offset-date --override $config";
    $ret = system("ssh $SBS_HOST \"$cmd\"");
    if($ret != 0){
        die("Hadoop failed!!!");
    }
    my $cp_cmd = "echo $pswd | sudo -u ihradmin -S /apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal /oih/sbs/$user/$tag/OihCalculation $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt";
    $ret = system("ssh $SBS_HOST \"$cp_cmd\"");
    if($ret != 0){
        die("Copy to local failed!!!");
    }

    if(defined($source)){
   
        print "*****************************************************************************************************************************\n\n";
        print "ETL Job CalendarMarkdownCategorizer is starting...\n\n";
        print "*****************************************************************************************************************************\n\n";

        my $source_cmd = "$env;echo $pswd | sudo -u ihradmin -S $root/bin/etl.pl --root $root --domain $domain --realm $realm --end-date $run_date --override $override_cfg --weekly --transforms CalendarMarkdownCategorizer --offset-date;";
        $ret = system("ssh $SBS_HOST \"$source_cmd\"");
        if($ret != 0){
            die("CBM categorizer failed!!!");
        }
        my $head_cmd = "head -1 $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt | awk -F \\\",\\\" 'BEGIN{OFS=\\\",\\\"}{NF -= 1;print \\\$0}' > $output_dir/tempfile ; ";
        my $awk_cmd = "awk -F ',' 'BEGIN{split(\\\"$source\\\",a,\\\",\\\");OFS=\\\",\\\"} {for(k in a)if(\\\$NF == a[k]){NF -= 1;print \\\$0;break}}' $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt >> $output_dir/tempfile; rm -f $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt; mv $output_dir/tempfile $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt"; 
        $cmd = $head_cmd.$awk_cmd;
        $ret = system("ssh $SBS_HOST \"$cmd\"");
        if($ret != 0){
            die("AWK failed!!!");
        }
    }
    print "\nHadoop Job is done.\n\n";

}

sub metrics{

    print "*****************************************************************************************************************************\n\n";
    print "ETL Job InventoryHealthMetrics is starting...\n\n";
    print "*****************************************************************************************************************************\n\n";

    my $CONFIG_FILE=$override_cfg;
    my $metrics_cmd = "$env;echo $pswd | sudo -u ihradmin -S /apollo/bin/env -e Prioritization $root/bin/etl.pl --domain $domain --realm $realm --end-date $run_date --override $CONFIG_FILE --weekly --transforms InventoryHealthMetrics --offset-date --scope all --model new";

    $ret = system("ssh $SBS_HOST \"$metrics_cmd\"");
    if($ret != 0){
        die("\nMetrics failed!!!\n\n");
    }else{
        print "\nETL Job InventoryHealthMetrics is done.\n\n";
    }

}

sub topn{

    print "*****************************************************************************************************************************\n\n";
    print "ETL Job TopAsin is starting...\n\n";
    print "*****************************************************************************************************************************\n\n";

    my $f1 = "UnhealthyAsinDetails-transformed.$date8\_to_$date1.old.txt";
    my $f2 = "UnhealthyAsinDetails-transformed.$date8\_to_$date1.new.txt";
    my $ORIG_FILE="$output_dir/$f1";
    my $NEW_FILE="$output_dir/$f2";
    my $CONFIG_FILE=$override_cfg;
    my $topn_cmd = "$env;";
    $topn_cmd .= " echo $pswd | sudo -u ihradmin -S $root/bin/etl.pl  --root $root --domain $domain --realm $realm --end-date $run_date --override $CONFIG_FILE --weekly --transforms TopAsinFileBased --other-option $ORIG_FILE,1,$NEW_FILE,1,10,700000 --offset-date;";
    $topn_cmd .= "mv $output_dir/TopAsinFileBased-transformed.$date8\_to_$date1.txt $output_dir/topn.$org.$run_date.csv";
    $ret = system("ssh $SBS_HOST \"$topn_cmd\"");
    if($ret != 0){
        die("\nTop Asin failed!!!\n\n");
    }else {
        print "\nETL Job TopAsin is done.\n\n";
    }
}

sub start_job{

    print "*****************************************************************************************************************************\n\n";
    print "SBS Job is starting...\n\n";
    print "*****************************************************************************************************************************\n\n";

    my $dir_cmd = "
    if [ ! -d \\\"$sbs_space\\\" ];then 
        echo 'not exist'
        mkdir $sbs_space
        mkdir $sbs_space/local-overrides
        chmod 777 $sbs_space -R
    else 
        echo 'exist'
    fi
    ";
    system("ssh $SBS_HOST \"$dir_cmd \"");

    my $clean_dir_cmd = "rm -rf $output_dir/*;rm -rf $override_dir/*";
    system("ssh $SBS_HOST \"$clean_dir_cmd\"");

    my @configs = (); 
    if(defined($cfg)){
        @configs = split(",",$cfg);
       
        foreach my $cfgfile (@configs){
            my $scp_cmd = "scp $cfgfile $SBS_HOST:$override_dir/$cfgfile";
            system($scp_cmd);
        }
    }
    
    my $sed_cmd = "sed -i 's/output-path=\\\"\\\/oih\\\/output\\\/\\\${rundate-1}\\\/\\\${domain}\\\/\\\${realm}\\\"/output-path=\\\"\\\/oih\\\/sbs\\\/$user\\\/$tag\\\"/g' $override_dir/OihCalculation.xml";
    my $override_cmd = "
    if [ ! -e $override_cfg ];then
        cp /apollo/env/Prioritization/brazil-config/override/Priority.cfg $override_cfg 
        chmod 777 $override_cfg 
    fi 
    echo '\n*.*.IhrMetrics.Output.Location=$output_dir;' >> $override_cfg
    ";
    system("ssh $SBS_HOST \"$override_cmd\"");

    my $override_cmd2 = "
    if [ ! -e $override_dir/OihCalculation.xml ];then
        cp $root/job-config/OihCalculation.xml $override_dir/OihCalculation.xml
    fi
    chmod 777 $override_dir/OihCalculation.xml
    $sed_cmd
    ";
    system("ssh $SBS_HOST \"$override_cmd2\""); 

    my $mail_cmd;
    my $s3_cmd;
    my $s3_dir = "$user/$org/$run_date/$tag";
    if($type eq 'once'){
        &hadoop_run;
        &metrics;
        $s3_cmd = "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt";
        system("ssh $SBS_HOST \"$s3_cmd\"");
    }

    if($type eq 'twice'){
        if(!defined($newjar)){
            die "You must specify option --newjar ***.jar while running with option --type twice";
        }

        if($oldjar){
            $jar = $oldjar;
            &hadoop_run;
            &metrics;
        }else{
            $jar = undef;
            &hadoop_run;
            &metrics;
        }
        my $mv_cmd = "mv $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.old.txt";
        $mv_cmd .= ";mv $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.old.txt";
        system("ssh $SBS_HOST \"$mv_cmd\"");

        if($newjar){
            $jar = $newjar;
            &hadoop_run;
            &metrics;
        }
        
        $mv_cmd = "mv $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.txt $output_dir/UnhealthyAsinDetails-transformed.$date8\_to_$date1.new.txt";
        $mv_cmd .= ";mv $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt";
        system("ssh $SBS_HOST \"$mv_cmd\"");
        &topn;

        $s3_cmd = "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.old.txt -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.old.txt";
        $s3_cmd .= "; /apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $output_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt";
        $s3_cmd .= "; /apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/topn.$org.$run_date.csv -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $output_dir/topn.$org.$run_date.csv";
        system("ssh $SBS_HOST \"$s3_cmd\"");
    }

    $mail_cmd = "echo 'SBS for $org on $run_date is done.\nThe output files have been uploaded to s3 bucket /oih_sbs/$s3_dir successfully.\n' | mail -s 'SBS for $org on $run_date is done.' $user\@amazon.com";

    my $clean_cmd = "echo $pswd | sudo -u ihradmin -S /apollo/env/OihHadoop/bin/apollo-hadoop fs -rm /oih/sbs/$user/$tag/OihCalculation";
    if(!defined($nodelete)){
        $clean_cmd .= ";rm -rf $output_dir";
    }else {
        $mail_cmd = "echo 'SBS for $org on $run_date is done.\nThe output files have been uploaded to s3 bucket /oih_sbs/$s3_dir successfully.\nThe detailed output files can be seen under directory $output_dir on host $SBS_HOST.\n' | mail -s 'SBS for $org on $run_date is done.' $user\@amazon.com";
    }
    system("ssh $SBS_HOST \"$mail_cmd\"");
    system("ssh $SBS_HOST \"$clean_cmd\"");
}

my $start_time = time();
&start_job;
my $end_time = time();

print "*****************************************************************************************************************************\n\n";
print "SBS Job is done...\n";
print("Took about " . sprintf("%0.0f", (($end_time - $start_time)/60)) . " minutes.\n\n");
print "*****************************************************************************************************************************\n\n";

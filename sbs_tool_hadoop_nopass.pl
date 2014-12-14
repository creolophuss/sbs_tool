#!/apollo/env/envImprovement/bin/perl
use strict;
use Getopt::Long;

my $run_date        = undef;
my $org             = undef;
my $help            = undef;
my $new_jar          = undef;
my $orig_jar        = undef;
my $pswd            = undef;
my $SBS_HOST        = undef;
my $type            = undef;
my $jar             = undef;
my $job_name        = undef;
my $tag             = "default";
my $nodelete        = undef;
my $source          = "OIH";
my $realm           = undef;
my $cfg             = undef;
my $orig_cfg        = undef;
my $new_cfg         = undef;
my $gl              = undef;
my $n               = 15;
my $opt_cmd         = undef;
my $orig_tag        = undef;
my $new_tag         = undef;

GetOptions(
    'cfg=s'         => \$cfg,
    'nodelete'      => \$nodelete,
    'tag=s'         => \$tag,
    'rundate=s'     => \$run_date,
    'org=s'         => \$org,
    'type=s'        => \$type,
    'jar=s'         => \$jar,
    'new-jar=s'     => \$new_jar,
    'orig-jar=s'    => \$orig_jar,
    'pswd=s'        => \$pswd,
    'source=s'      => \$source,
    'realm=s'       => \$realm,
    'orig-cfg=s'    => \$orig_cfg,
    'new-cfg=s'     => \$new_cfg,
    'help|?'        => \$help,
    'n=s'           => \$n,
    'cmd=s'         => \$opt_cmd,
    'orig-tag=s'    => \$orig_tag,
    'new-tag=s'     => \$new_tag,
) or die "canot parse command line options.";

my $domain = 'prod';
my $root = '/apollo/env/Prioritization';
my $config = '/apollo/env/Prioritization/brazil-config/override/Priority.cfg';
my $job_config = undef;
my $cbm_enabled = undef;
my $enable_book = undef;

if($org eq "CN"){
    $enable_book = 0;
}else{
    $enable_book = 1;
}

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

if($org eq "US" || $org eq "CN" || $org eq "JP"){
    print "$org  : cmb enabled";
    $cbm_enabled = 1;
}else{
    $cbm_enabled = 0;
}

if(!defined($realm)){
    $realm = $org.'Amazon';
}

$job_name = $realm."OihCalculation";
my $env = undef;
my $script = undef;

if ($org eq "US"){

    $env =
"export TZ=US/Pacific;
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
    $SBS_HOST = "scos-oih-gamma-hadoop-i-5daf9177.us-east-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-cn-calculation-gamma-38002.pek50.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-hadoop-i-5daf9177.us-east-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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
    $SBS_HOST = "scos-oih-gamma-eu-hadoop-i-bf75f8fc.eu-west-1.amazon.com";
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


$script = $env;
my $user = $ENV{'USER'};
my $sbs_space = "/home/$user/sbs_space";

my $override_dir = "$sbs_space/local-overrides";
my $local_dir = undef;
my $report_root = "/oih/report/$user/$tag";
my $prod_root = "/oih/prod_files/$realm/$date1";


$local_dir = "$root/var/output/data/$domain/$realm/$user";

print "Initialize local output directory.\n";
my $local_dir_cmd = "
if [ ! -d \\\"$local_dir\\\" ];then 
    mkdir $local_dir
    chmod 777 $local_dir
fi
";
system("ssh $SBS_HOST \"$local_dir_cmd\"");
$local_dir .= "/$tag";
system("ssh $SBS_HOST \"mkdir $local_dir && chmod 777 $local_dir\"");

my $s3_dir = "$user/$org/$run_date/$tag";
my $mail_cmd;
my $s3_cmd;
sub start_job{

    print "******************************\n";
    print "*   SBS Job is starting...   *\n";
    print "******************************\n";
    
    &init_sbs_space;
   
    my $jar_name = undef;
    my $calculation_jar = undef;
    my $asin_detail_file_orig = undef;
    my $asin_detail_file_new = undef;
    if($type eq 'once'){
        
        if(defined($jar)){
            $jar_name = `basename $jar`;
            $calculation_jar = "$sbs_space/$tag/local-overrides/".$jar_name;
        }

        $override_dir = "$sbs_space/$tag/local-overrides";
        &oih_calculation($calculation_jar);
        my $asin_detail_file = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.sbs.txt";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv /oih/sbs/$user/$tag/OihCalculation $asin_detail_file\n";

        &cbm_categorizer($asin_detail_file);
        $asin_detail_file = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt";
        if(defined($nodelete)){
            $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $asin_detail_file $local_dir\n";
        }
        &ihmetrics($asin_detail_file);
        $asin_detail_file_new = $asin_detail_file;
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt $local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt\n";
        $s3_cmd = "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt\n";
    }

    if($type eq 'twice'){
        if(!defined($orig_jar)){
            die "You must specify option --orig-jar ***.jar while running with option --type twice";
        }

        if(!defined($new_jar)){
            die "You must specify option --new-jar ***.jar while running with option --type twice";
        }

        if(defined($orig_jar)){
            $jar_name = `basename $orig_jar`;
            $calculation_jar = "$sbs_space/$tag/orig-overrides/".$jar_name;
        }
        $override_dir = "$sbs_space/$tag/orig-overrides";
        &oih_calculation($calculation_jar);
        $asin_detail_file_orig = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.orig.txt";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv /oih/sbs/$user/$tag/OihCalculation $asin_detail_file_orig\n";
        &cbm_categorizer($asin_detail_file_orig);
        $asin_detail_file_orig = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.orig.txt";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv $report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt $asin_detail_file_orig\n";
        if(defined($nodelete)){
            $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $asin_detail_file_orig $local_dir\n";
        }

        &ihmetrics($asin_detail_file_orig);
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.orig.txt\n";

        if(defined($new_jar)){
            $jar_name = `basename $new_jar`;
            $calculation_jar = "$sbs_space/$tag/new-overrides/".$jar_name;
        }
        
        $override_dir = "$sbs_space/$tag/new-overrides";
        &oih_calculation($calculation_jar);
        $asin_detail_file_new = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.new.txt";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv /oih/sbs/$user/$tag/OihCalculation $asin_detail_file_new\n";
        &cbm_categorizer($asin_detail_file_new);
        $asin_detail_file_new = "$report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.new.txt";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv $report_root/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt $asin_detail_file_new\n";
        if(defined($nodelete)){
            $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $asin_detail_file_new $local_dir\n";
        }
        &ihmetrics($asin_detail_file_new);
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt\n";
        
        &topn($asin_detail_file_orig,$asin_detail_file_new);

        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $report_root/TopAsin.csv $local_dir/TopAsinFileBased-transformed.$date1.csv\n";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.orig.txt $local_dir\n";
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $report_root/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt $local_dir\n";
    

        &create_sbs_report("$local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.orig.txt","$local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt");
        $s3_cmd = "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthSideBySide-transformed.$date8\_to_$date1.xlsx -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $local_dir/InventoryHealthSideBySide-transformed.$date8\_to_$date1.xlsx\n";
        $s3_cmd .= "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/TopAsinFileBased-transformed.$date1.csv -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $local_dir/TopAsinFileBased-transformed.$date1.csv\n";
    }
    
    
    $script .= $s3_cmd;
    $mail_cmd = "echo 'SBS for $org on $run_date is done.\nThe output files have been uploaded to s3 bucket /oih_sbs/$s3_dir successfully.\n' | mail -s 'SBS for $org on $run_date is done.' $user\@amazon.com\n";

    my $clean_cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop fs -rmr $report_root\n";
    $clean_cmd .= "rm -rf $sbs_space/$tag\n";
    if(!defined($nodelete)){
        $clean_cmd .= "rm -rf $local_dir\n";
        $script .= $clean_cmd;
    }else {
        $mail_cmd = "echo 'SBS for $org on $run_date is done.\nThe output files have been uploaded to s3 bucket /oih_sbs/$s3_dir successfully.\nThe detailed output files can be seen under directory $local_dir on host $SBS_HOST.\n' | mail -s 'SBS for $org on $run_date is done.' $user\@amazon.com";
    }
    $script .= $mail_cmd;
    
    `echo \"$script\" > sbs_script.sh`;
    `chmod +x sbs_script.sh`;
    `scp sbs_script.sh $SBS_HOST:$sbs_space/$tag/`;
    system("ssh $SBS_HOST \"echo $pswd | sudo -u ihradmin -S $sbs_space/$tag/sbs_script.sh\"");
}

sub init_sbs_space {

    print "**********************************\n";
    print "*   Initializing SBS space ...   *\n";
    print "**********************************\n";
    my $dir_cmd = "
    echo $pswd | sudo -u ihradmin -S /apollo/env/OihHadoop/bin/apollo-hadoop fs -mkdir $report_root

    if [ ! -d \\\"/home/$user\\\" ]];then
        echo 'Directory /home/$user does not exist , create one.'
        echo $pswd | sudo -S mkdir /home/$user
        echo $pswd | sudo -S chmod 777 /home/$user
    fi

    if [ ! -d \\\"$sbs_space\\\" ];then 
        echo 'Directory $sbs_space does not exist , create one.'
        mkdir $sbs_space
    fi

    if [ ! -d \\\"$sbs_space/$tag\\\" ];then 
        mkdir $sbs_space/$tag
    fi
    ";

    my $sub_dir_cmd = undef;
    my @configs = (); 
    if($type eq "once"){
        $sub_dir_cmd = "
        if [ ! -d \\\"$sbs_space/$tag/local-overrides\\\" ];then 
            echo 'Directory $sbs_space/$tag/local-overrides does not exist,create one.'
            mkdir $sbs_space/$tag/local-overrides
        fi
        rm -rf $sbs_space/$tag/local-overrides/*

        ";
        
    }else{
        $sub_dir_cmd = "
        if [ ! -d \\\"$sbs_space/$tag/orig-overrides\\\" ];then 
            echo 'Directory $sbs_space/$tag/orig-overrides does not exist,create one.'
            mkdir $sbs_space/$tag/orig-overrides
        fi
        rm -rf $sbs_space/$tag/orig-overrides/*

        if [ ! -d \\\"$sbs_space/$tag/new-overrides\\\" ];then 
            echo 'dir $sbs_space/$tag/new-overrides does not exist,create one.'
            mkdir $sbs_space/$tag/new-overrides
        fi
        rm -rf $sbs_space/$tag/new-overrides/*
        ";
    }

    $dir_cmd = $dir_cmd.$sub_dir_cmd."chmod 777 $sbs_space -R";
    system("ssh $SBS_HOST \"$dir_cmd \"");

    if($type eq 'once'){

        if(defined($cfg)){
            @configs = split(",",$cfg);
           
            foreach my $cfgfile (@configs){
                my $basename = undef;
                $basename=`basename $cfgfile`;
                my $scp_cmd = "scp $cfgfile $SBS_HOST\:$sbs_space/$tag/local-overrides/$basename";
                system($scp_cmd);
            }
        }

        if(defined($jar)){
            my $jar_name = `basename $jar`;
            `scp $jar $SBS_HOST\:$sbs_space/$tag/local-overrides/$jar_name`;
        }
           

        $dir_cmd = "
        if [ ! -e $sbs_space/$tag/local-overrides/OihCalculation.xml ];then
            cp $root/job-config/OihCalculation.xml $sbs_space/$tag/local-overrides/OihCalculation.xml
        fi
        chmod 777 $sbs_space/$tag/local-overrides/OihCalculation.xml
        sed -i 's/output-path=\\\"\\\/oih\\\/output\\\/\\\${rundate-1}\\\/\\\${domain}\\\/\\\${realm}\\\"/output-path=\\\"\\\/oih\\\/sbs\\\/$user\\\/$tag\\\"/g' $sbs_space/$tag/local-overrides/OihCalculation.xml";
    }elsif($type eq 'twice'){
    
        if(defined($orig_cfg)){
            @configs = split(",",$orig_cfg);
           
            foreach my $cfgfile (@configs){
                my $basename = undef;
                $basename=`basename $cfgfile`;
                my $scp_cmd = "scp $cfgfile $SBS_HOST\:$sbs_space/$tag/orig-overrides/$basename";
                system($scp_cmd);
            }
        }
       
        if(defined($new_cfg)){
            @configs = split(",",$new_cfg);
           
            foreach my $cfgfile (@configs){
                my $basename = undef;
                $basename=`basename $cfgfile`;
                my $scp_cmd = "scp $cfgfile $SBS_HOST\:$sbs_space/$tag/new-overrides/$basename";
                system($scp_cmd);
            }
        }
        if(defined($orig_jar)){
            my $jar_name = `basename $orig_jar`;
            `scp $orig_jar $SBS_HOST\:$sbs_space/$tag/orig-overrides/$jar_name`;
        }
        
        if(defined($new_jar)){
            my $jar_name = `basename $new_jar`;
            `scp $new_jar $SBS_HOST\:$sbs_space/$tag/new-overrides/$jar_name`;
        }else{
            die "You must specify option --newjar ***.jar while running with option --type twice";
        }

        $dir_cmd = "
        if [ ! -e $sbs_space/$tag/orig-overrides/OihCalculation.xml ];then
            cp $root/job-config/OihCalculation.xml $sbs_space/$tag/orig-overrides/OihCalculation.xml
        fi
        chmod 777 $sbs_space/$tag/orig-overrides/OihCalculation.xml
        sed -i 's/output-path=\\\"\\\/oih\\\/output\\\/\\\${rundate-1}\\\/\\\${domain}\\\/\\\${realm}\\\"/output-path=\\\"\\\/oih\\\/sbs\\\/$user\\\/$tag\\\"/g' $sbs_space/$tag/orig-overrides/OihCalculation.xml;
        
        if [ ! -e $sbs_space/$tag/new-overrides/OihCalculation.xml ];then
            cp $root/job-config/OihCalculation.xml $sbs_space/$tag/new-overrides/OihCalculation.xml
        fi
        chmod 777 $sbs_space/$tag/new-overrides/OihCalculation.xml
        sed -i 's/output-path=\\\"\\\/oih\\\/output\\\/\\\${rundate-1}\\\/\\\${domain}\\\/\\\${realm}\\\"/output-path=\\\"\\\/oih\\\/sbs\\\/$user\\\/$tag\\\"/g' $sbs_space/$tag/new-overrides/OihCalculation.xml";
    }
    system("ssh $SBS_HOST \"$dir_cmd \"");
}
sub oih_calculation{

    my $jar_path = shift;
    chomp $jar_path;
    
    $script .= "echo '************************************************'\n";
    $script .= "echo '*   Hadoop Job OihCalculation is starting...   *'\n";
    $script .= "echo '************************************************'\n";
    my $cmd="/apollo/env/OihHadoop/bin/apollo-hadoop "; 
    my $main_class;

    $job_config = "$override_dir/OihCalculation.xml";
    if(defined($jar_path)){
        $main_class = "com.amazon.oih.hadoop.MyJobBootStrap";
    }else{
        $jar_path = "/apollo/env/Prioritization/lib/HadoopJobEngineInterface-1.0.jar";
        $main_class = "com.amazon.oih.hadoop.JobBootStrap";
    }
    $cmd .= "jar $jar_path $main_class ";

    $cmd .= " --confFile $job_config --realm $realm --rundate $run_date --jobName $job_name --domain $domain --root $root --appgroup Oih --start-date $date7 --end-date $date0 --appname OihMetrics --offset-date --override $config\n";
    $script = $script.$cmd;
    $script .= "echo '*******************************************'\n";
    $script .= "echo '*   Hadoop Job OihCalculation is done .   *'\n";
    $script .= "echo '*******************************************'\n";
}

sub cbm_categorizer{
    
    my $input_file = shift;
    my $cmd = undef;
    
    if($cbm_enabled == 1){
        $script .= "echo '*********************************************'\n";
        $script .= "echo '*   Hadoop Job Categorizer is starting...   *'\n";
        $script .= "echo '*********************************************'\n";

        $cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop jar /apollo/env/Prioritization/lib/OihCBM-1.0.jar com.amazon.oih.markdowns.transform.mapreduce.Categorizer.CategorizerJob --in $input_file  --start_date $date8 --end_date $date1 --tag $user/$tag --realm $realm\n";

        $script .= $cmd;
        $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -rm $input_file\n";
        $script .= "echo '****************************************'\n";
        $script .= "echo '*   Hadoop Job Categorizer is done .   *'\n";
        $script .= "echo '****************************************'\n";
    }else{
        $cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop fs -mv $input_file /oih/report/$user/$tag/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt\n";
        $script .= $cmd;
    }
}

sub ihmetrics{
    my $input = shift;
    $script .= "echo '*******************************************'\n";
    $script .= "echo '*   Hadoop Job IHMetrics is starting...   *'\n";
    $script .= "echo '*******************************************'\n";

    my $cmd = undef;
    $cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop jar /apollo/env/Prioritization/lib/OihMetrics.jar com.amazon.invhealth.metrics.transform.mapreduce.ihmetrics.IHMetricsJob  --in $input --realm $realm --tag $user/$tag --start_date $date8 --end_date $date1";
    if($cbm_enabled == 1){
        $cmd .= " --source $source";
    }

    if($enable_book == 1){
        $cmd .= " --book";
    }
    
    $cmd .= "\n";
    
    $script .= $cmd;
    $script .= "echo '**************************************'\n";
    $script .= "echo '*   Hadoop Job IHMetrics is done .   *'\n";
    $script .= "echo '**************************************'\n";
}

sub topn{
    my $orig_file = shift;
    my $new_file = shift;
    $script .= "echo '*****************************************'\n";
    $script .= "echo '*   Hadoop Job TopAsin is starting...   *'\n";
    $script .= "echo '*****************************************'\n";

    my $cmd = undef;
    $cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop jar /apollo/env/Prioritization/lib/OihMetrics.jar com.amazon.invhealth.metrics.transform.mapreduce.topasin.TopAsinJob --orig_file $orig_file --new_file $new_file -n $n --tag $user/$tag";

    if($cbm_enabled == 1){
        $cmd .= " --source $source\n";
    }else{
        $cmd .= "\n";
    }

    $script .= $cmd;
    $script .= "echo '************************************'\n";
    $script .= "echo '*   Hadoop Job TopAsin is done .   *'\n";
    $script .= "echo '************************************'\n";
}

sub create_sbs_report{
    $script .= "echo '********************************************************'\n";
    $script .= "echo '*   ETL Job InventoryHealthSideBySide is starting...   *'\n";
    $script .= "echo '********************************************************'\n";

    my $orig_file = "$local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.orig.txt";
    my $new_file =  "$local_dir/InventoryHealthMetrics-transformed.$date8\_to_$date1.new.txt";
    my $orig_file = shift;
    my $new_file = shift;
    my $template_path = "/apollo/env/Prioritization/templates/SBS_excel_template.xlsx";
    my $threshold = 0.06;
    my $output_file_path = "$local_dir/InventoryHealthSideBySide-transformed.$date8\_to_$date1.xlsx";

    my $config_file = "/apollo/env/Prioritization/brazil-config/override/Priority.cfg";
    my $PLCMD = "$root/bin/etl.pl";
    my $cmd = undef;
    
    $cmd = "/apollo/bin/env -e Prioritization $PLCMD --domain prod --realm $realm --end-date $date1 --override $config_file --weekly  --offset-date --transforms InventoryHealthSideBySide --other-option orig=$orig_file,new=$new_file,template=$template_path,threshold=$threshold,out=$output_file_path,mail-to=$user\@amazon.com,book-flag=true\n";
    $script .= $cmd;
    $script .= "echo '********************************************************'\n";
    $script .= "echo '*   ETL Job InventoryHealthSideBySide is done .        *'\n";
    $script .= "echo '********************************************************'\n";

}

sub output_analysis_file{
    my $asin_detail_orig = "/oih/report/$user/$orig_tag/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt";
    my $asin_detail_new = "/oih/report/$user/$new_tag/UnhealthyAsinDetails-transformed.$date8\_to_$date1.categorized.txt";
    my $metrics_orig = "$root/var/output/data/$domain/$realm/$user/$orig_tag/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt";
    my $metrics_new = "$root/var/output/data/$domain/$realm/$user/$new_tag/InventoryHealthMetrics-transformed.$date8\_to_$date1.txt";
    &init_sbs_space;

    &topn($asin_detail_orig,$asin_detail_new);
    &create_sbs_report($metrics_orig,$metrics_new);
    
    $script .= "/apollo/env/OihHadoop/bin/apollo-hadoop fs -copyToLocal $report_root/TopAsin.csv $local_dir/TopAsinFileBased-transformed.$date1.csv\n";
    $s3_cmd = "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/InventoryHealthSideBySide-transformed.$date8\_to_$date1.xlsx -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $local_dir/InventoryHealthSideBySide-transformed.$date8\_to_$date1.xlsx\n";
    $s3_cmd .= "/apollo/env/envImprovement/bin/s3PutFile -o $s3_dir/TopAsinFileBased-transformed.$date1.csv -b oih_sbs -c com.amazon.access.OIH-oih-cn-1 $local_dir/TopAsinFileBased-transformed.$date1.csv\n";
    $script .= $s3_cmd;
    
    my $clean_cmd = "/apollo/env/OihHadoop/bin/apollo-hadoop fs -rmr $report_root\n";
    $clean_cmd .= "rm -rf $sbs_space/$tag\n";
    if(!defined($nodelete)){
        $clean_cmd .= "rm -rf $local_dir\n";
        $script .= $clean_cmd;
    }else {
        $mail_cmd = "echo 'SBS for $org on $run_date is done.\nThe output files have been uploaded to s3 bucket /oih_sbs/$s3_dir successfully.\nThe detailed output files can be seen under directory $local_dir on host $SBS_HOST.\n' | mail -s 'SBS for $org on $run_date is done.' $user\@amazon.com";
    }
    $script .= $mail_cmd;
    
    `echo \"$script\" > sbs_script.sh`;
    `chmod +x sbs_script.sh`;
    `scp sbs_script.sh $SBS_HOST:$sbs_space/$tag/`;
    system("ssh $SBS_HOST \"echo $pswd | sudo -u ihradmin -S $sbs_space/$tag/sbs_script.sh\"");
}

if($opt_cmd eq "report"){
    &output_analysis_file;

}else{
    &start_job;
}

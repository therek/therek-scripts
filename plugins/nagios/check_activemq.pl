#!/usr/bin/perl

use strict;
use Net::Stomp;

my $time=time;
my @hosts=qw /mybroker1 mybroker2/;
my $login='client';
my $pass='mypass';
my $queue='/queue/nagiosTestQueue';
my %error=('ok'=>0,'warning'=>1,'critical'=>2);
my ($exitcode, $evalcount);

# Tryout each broker in the @hosts array
foreach ( @hosts ) {
    eval {
        # Connect to the broker.
        my $stomp = Net::Stomp->new(
            { hostname => "$_",
              port     => '61613'
            }
        );
        $stomp->connect(
            { login    => "$login",
              passcode => "$pass"
            }
        );
        # Send test message containing $time timestamp.
        $stomp->send( 
            { destination => "$queue",
              body        => "$time"
            }
        );
       
        # Subscribe to messages from the $queue.
        $stomp->subscribe(
            { destination             => "$queue",
              'ack'                   => 'client',
              'activemq.prefetchSize' => 1
            }
        );
        my $success_flag = 0;
	# Iterate through all messages in queue
        while ( $stomp->can_read({ timeout => "5" }) ) {
            my $frame = $stomp->receive_frame;
            $stomp->ack( { frame => $frame } );
            my $framebody=$frame->body;

            if ( $framebody eq "$time" ) {
                print "OK: Message received\n";
                $exitcode="ok";
                $success_flag = 1;
                last;
            }
        }
        unless ( $success_flag ) {
            # There's still to message to collect.
            print "CRITICAL: Timed out while trying to collect the message\n";
            $exitcode="critical";
        }
        # Whatever the outcome, we have managed to connect to given broker.
        # There's no need to try the other.
        $stomp->disconnect;
        exit $error{"$exitcode"};
    };
    # $@ contains error message from eval() which means the execution
    # of eval() block did not succeed.
    ++$evalcount if $@;
}

print "CRITICAL: No connection to ActiveMQ; tried $evalcount out of " . @hosts . " brokers\n";
exit $error{"critical"};


use Test::More;
use DateTime;
use lib 't/lib';

use_ok 'Order';
use_ok 'OpenCloset::Calculator::LateFee';

# 연체료: 7_500 per day

my $tz    = 'Asia/Seoul';
my $today = DateTime->today( time_zone => $tz );
my $calc  = OpenCloset::Calculator::LateFee->new( ignore_status => 1 );

ok( $calc, 'new' );

my $order = Order->new;

$order->target_date( $today->clone );
$order->user_target_date( $today->clone );
is( $calc->overdue_days($order), 0, '반납예정일(D-Day)' );
is( $calc->overdue_fee($order),  0, '연체료(D-day)' );

$order->target_date( $today->clone->subtract( days => 2 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->overdue_days($order), 1,    '반납예정일(-1d)' );
is( $calc->overdue_fee($order),  7500, '연체료(-1d)' );

$order->target_date( $today->clone->subtract( days => 3 ) );
$order->user_target_date( $today->clone->subtract( days => 2 ) );
is( $calc->overdue_days($order), 2,     '반납예정일(-2d)' );
is( $calc->overdue_fee($order),  15000, '연체료(-2d)' );

$order->target_date( $today->clone->subtract( days => 4 ) );
$order->user_target_date( $today->clone->subtract( days => 3 ) );
is( $calc->overdue_days($order), 3,     '반납예정일(-3d)' );
is( $calc->overdue_fee($order),  22500, '연체료(-3d)' );

$order->target_date( $today->clone );
$order->user_target_date( $today->clone->add( days => 1 ) );
is( $calc->overdue_days($order), 0, '반납예정일(+1d)' );
is( $calc->overdue_fee($order),  0, '연체료(+1d)' );

done_testing;

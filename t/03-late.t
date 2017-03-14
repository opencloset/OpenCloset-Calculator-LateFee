use Test::More;
use DateTime;
use lib 't/lib';

use_ok 'Order';
use_ok 'OpenCloset::Calculator::LateFee';

# 연체료: 7_500 per day
# 연장료: 5_000 per day

my $tz    = 'Asia/Seoul';
my $today = DateTime->today( time_zone => $tz );
my $calc  = OpenCloset::Calculator::LateFee->new;
my $order = Order->new;

$order->target_date( $today->clone );
$order->user_target_date( $today->clone );
is( $calc->late_fee($order), 0, '연장(0d)+연체(0d)' );

$order->target_date( $today->clone->subtract( days => 2 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->late_fee($order), 12500, '연체(1d)+연장(1d)' );

$order->target_date( $today->clone->subtract( days => 3 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->late_fee($order), 17500, '연체(1d)+연장(2d)' );

$order->target_date( $today->clone->subtract( days => 4 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->late_fee($order), 22500, '연체(1d)+연장(3d)' );

$order->target_date( $today->clone->subtract( days => 3 ) );
$order->user_target_date( $today->clone->subtract( days => 2 ) );
is( $calc->late_fee($order), 20000, '연체(2d)+연장(1d)' );

$order->target_date( $today->clone->add( days => 1 ) );
$order->user_target_date( $today->clone->add( days => 1 ) );
is( $calc->late_fee($order), 0, '연체(0d)+연장(0d)' );

done_testing;

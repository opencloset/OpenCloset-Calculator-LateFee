use Test::More;
use DateTime;
use lib 't/lib';

use_ok 'Order';
use_ok 'OpenCloset::Calculator::LateFee';

# 연장료: 5_000 per day

my $tz    = 'Asia/Seoul';
my $today = DateTime->today( time_zone => $tz );
my $calc  = OpenCloset::Calculator::LateFee->new;
my $order = Order->new;

$order->target_date( $today->clone );
$order->user_target_date( $today->clone );
is( $calc->extension_days($order), 0, '반납희망일(D-Day)' );
is( $calc->extension_fee($order),  0, '연장료(D-day)' );

$order->target_date( $today->clone->subtract( days => 2 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->extension_days($order), 1,    '반납희망일 - 반납예정일 = 1d' );
is( $calc->extension_fee($order),  5000, '연장료(1d)' );

$order->target_date( $today->clone->subtract( days => 3 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->extension_days($order), 2,     '반납희망일 - 반납예정일 = 2d' );
is( $calc->extension_fee($order),  10000, '연장료(2d)' );

$order->target_date( $today->clone->subtract( days => 4 ) );
$order->user_target_date( $today->clone->subtract( days => 1 ) );
is( $calc->extension_days($order), 3,     '반납희망일 - 반납예정일 = 3d' );
is( $calc->extension_fee($order),  15000, '연장료(3d)' );

$order->target_date( $today->clone->add( days => 1 ) );
$order->user_target_date( $today->clone->add( days => 1 ) );
is( $calc->extension_days($order), 0, '반납일 < 반납희망일' );
is( $calc->extension_fee($order),  0, '연장료(0d)' );

done_testing;

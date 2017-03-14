use Test::More;
use DateTime;

use lib 't/lib';

use Order;
use OpenCloset::Calculator::LateFee;

# 연체료: 7_500 per day
# 연장료: 5_000 per day

my $tz    = 'Asia/Seoul';
my $calc  = OpenCloset::Calculator::LateFee->new;
my $order = Order->new;
my $today = '2017-03-15T06:00:00';

$order->target_date(
    DateTime->new(
        year      => 2017,
        month     => 3,
        day       => 10,
        time_zone => $tz,
    )
);
$order->user_target_date(
    DateTime->new(
        year      => 2017,
        month     => 3,
        day       => 10,
        time_zone => $tz,
    )
);

is( $calc->overdue_days( $order, $today ), 5, 'overdue_days' );
is( $calc->overdue_fee( $order, $today ), 37500, 'overdue_fee' );
is( $calc->extension_days( $order, $today ), 0, 'extension_days' );
is( $calc->extension_fee( $order, $today ), 0, 'extension_fee' );
is( $calc->late_fee( $order, $today ), 37500, 'late_fee' );

$order->target_date(
    DateTime->new(
        year      => 2017,
        month     => 2,
        day       => 28,
        time_zone => $tz,
    )
);

$order->user_target_date(
    DateTime->new(
        year      => 2017,
        month     => 3,
        day       => 18,
        time_zone => $tz,
    )
);

is( $calc->overdue_days( $order, $today ), 0, 'overdue_days' );
is( $calc->overdue_fee( $order, $today ), 0, 'overdue_fee' );
is( $calc->extension_days( $order, $today ), 15, 'extension_days' );
is( $calc->extension_fee( $order, $today ), 75000, 'extension_fee' );
is( $calc->late_fee( $order, $today ), 75000, 'late_fee' );

$order->target_date(
    DateTime->new(
        year      => 2017,
        month     => 3,
        day       => 6,
        time_zone => $tz,
    )
);

$order->user_target_date(
    DateTime->new(
        year      => 2017,
        month     => 3,
        day       => 7,
        time_zone => $tz,
    )
);

is( $calc->overdue_days( $order, $today ), 8, 'overdue_days' );
is( $calc->overdue_fee( $order, $today ), 60000, 'overdue_fee' );
is( $calc->extension_days( $order, $today ), 1, 'extension_days' );
is( $calc->extension_fee( $order, $today ), 5000, 'extension_fee' );
is( $calc->late_fee( $order, $today ), 65000, 'late_fee' );

done_testing;

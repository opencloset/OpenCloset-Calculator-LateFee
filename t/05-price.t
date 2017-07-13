use utf8;
use strict;
use warnings;

use open ':std', ':encoding(utf8)';
use Test::More;

use OpenCloset::Calculator::LateFee;
use OpenCloset::Schema;

use lib '/home/aanoaa/repo/opencloset/OpenCloset-API/lib';
use OpenCloset::API::Order;

use lib 't/lib';
use Param::Order qw/order_param/;
use Param::Coupon qw/coupon_param/;

my $schema = OpenCloset::Schema->connect(
    {
        dsn  => $ENV{OPENCLOSET_DATABASE_DSN}  || "dbi:mysql:opencloset:127.0.0.1",
        user => $ENV{OPENCLOSET_DATABASE_USER} || 'opencloset',
        password => $ENV{OPENCLOSET_DATABASE_PASS} // 'opencloset',
        quote_char        => q{`},
        mysql_enable_utf8 => 1,
        on_connect_do     => 'SET NAMES utf8',
        RaiseError        => 1,
        AutoCommit        => 1,
    }
);

my $hostname = `hostname`;
my $username = $ENV{USER};

if ( $username eq 'opencloset' or $hostname =~ m/opencloset/ ) {
    plan skip_all => 'Do not run on service host';
}

my $api = OpenCloset::API::Order->new( schema => $schema, notify => 0 );
my $calc = OpenCloset::Calculator::LateFee->new;
ok( $calc, 'OpenCloset::Calculator::LateFee->new' );

our @CODES = qw/0J001 0P001 0S003 0A001 0E000/;

subtest 'normal' => sub {
    my $user = $schema->resultset('User')->find( { id => 3 } );
    $user->delete_related('orders');

    my $param = order_param($schema);
    $param->{user_id} = $user->id;

    my $order = $schema->resultset('Order')->create($param);
    $api->box2boxed( $order, \@CODES );

    my $price    = $calc->price($order);
    my $discount = $calc->discount_price($order);

    is( $price,    32_000, 'price' );
    is( $discount, 0,      'discount' );

    $api->boxed2payment($order);
    $api->payment2rental( $order, price_pay_with => '현금' );

    my $target_date = $order->target_date;
    my $user_target_date = $target_date->clone->add( days => 2 );
    $order->update( { user_target_date => $user_target_date->datetime } );

    my $return_date = $user_target_date->clone->add( days => 2 );
    $api->rental2returned( $order, return_date => $return_date, late_fee_pay_with => '미납' );

    my $extension_fee = $calc->extension_fee($order);
    my $overdue_fee   = $calc->overdue_fee($order);
    is( $extension_fee, 12_800, 'extension_fee' );
    is( $overdue_fee,   19_200, 'overdue_fee' );

    ## TODO: 미납금
};

subtest '3times' => sub {
    my $param = order_param($schema);
    $param->{user_id} = 2;

    my $order = $schema->resultset('Order')->create($param);
    $api->box2boxed( $order, \@CODES );

    my $price    = $calc->price($order);
    my $discount = $calc->discount_price($order);

    is( $price,    32_000,  'price' );
    is( $discount, -12_000, 'discount' );

    ## TODO: 연체비/연장비
    ## TODO: 미납금
};

subtest 'coupon - suit' => sub {
    my $coupon_param = coupon_param( $schema, 'suit' );
    my $coupon       = $schema->resultset('Coupon')->create($coupon_param);
    my $param        = order_param($schema);
    $param->{user_id}   = 2;
    $param->{coupon_id} = $coupon->id;

    my $order = $schema->resultset('Order')->create($param);
    $api->box2boxed( $order, \@CODES );

    my $price    = $calc->price($order);
    my $discount = $calc->discount_price($order);

    is( $price,    32_000,  'price' );
    is( $discount, -32_000, 'discount' );

    ## TODO: 연체비/연장비
    ## TODO: 미납금
};

subtest 'coupon - default(price)' => sub {
    my $coupon_param = coupon_param( $schema, 'default' );
    my $coupon       = $schema->resultset('Coupon')->create($coupon_param);
    my $param        = order_param($schema);
    $param->{user_id}   = 2;
    $param->{coupon_id} = $coupon->id;

    my $order = $schema->resultset('Order')->create($param);
    $api->box2boxed( $order, \@CODES );

    my $price    = $calc->price($order);
    my $discount = $calc->discount_price($order);

    is( $price,    32_000,  'price' );
    is( $discount, -13_000, 'discount' );

    ## TODO: 연체비/연장비
    ## TODO: 미납금
};

subtest 'coupon - rate' => sub {
    my $coupon_param = coupon_param( $schema, 'rate' );
    my $coupon       = $schema->resultset('Coupon')->create($coupon_param);
    my $param        = order_param($schema);
    $param->{user_id}   = 2;
    $param->{coupon_id} = $coupon->id;

    my $order = $schema->resultset('Order')->create($param);
    $api->box2boxed( $order, \@CODES );

    my $price    = $calc->price($order);
    my $discount = $calc->discount_price($order);

    is( $price,    32_000, 'price' );
    is( $discount, -9_600, 'discount' );

    ## TODO: 연체비/연장비
    ## TODO: 미납금
};

done_testing();

package OpenCloset::Calculator::LateFee;

use utf8;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;

use OpenCloset::Constants::Status qw/$RENTAL $RETURNED $CHOOSE_CLOTHES $CHOOSE_ADDRESS $PAYMENT $PAYMENT_DONE $WAITING_DEPOSIT $PAYBACK/;

=encoding utf8

=head1 NAME

OpenCloset::Calculator::LateFee - late_fee, overdue_fee and extension_fee calculator

=head1 SYNOPSIS

대여비: 의류대여비 - 할인금액

    my $calc         = OpenCloset::Calculator::LateFee->new;
    my $discount     = $calc->discount_price($order); # 할인금액 총합
    my $overdue_days = $calc->overdue_days($order);   # 연체일: 오늘 - 반납희망일
    my $overdue_fee  = $calc->overdue_fee($order);    # 연체료: 대여비 * 연체일 * 0.3
    my $ext_days     = $calc->extension_days($order); # 연장일: 반납희망일 - 반납예정일
    my $ext_fee      = $calc->extension_fee($order);  # 연장비: 대여비 * 연장일 * 0.2
    my $late_fee     = $calc->late_fee($order);       # 연장비 + 연체비

=head1 METHODS

=head2 new

    my $calc = OpenCloset::Calculator::LateFee->new;    # default timezone is 'Asia/Seoul'
    my $calc = OpenCloset::Calculator::LateFee->new(timezone => 'Asia/Seoul');

    # Calculate fees only target_date, user_target_date and return_date
    my $calc = OpenCloset::Calculator::LateFee->new(ignore_status => 1);

=cut

our $DAY_AS_SECONDS = 60 * 60 * 24;
our $EXTENSION_RATE = 0.2;
our $OVERDUE_RATE   = 0.3;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        ignore   => $args{ignore_status},
        timezone => $args{timezone} || 'Asia/Seoul',
    };

    bless $self, $class;
    return $self;
}

=head2 price( $order )

    my $price = $self->price($order);    # 20000

B<최종대여가격|대여가격> 이 아닌 B<정상금액>입니다.

    정상금액 = 대여 의류 품목 가격의 합
    할인금액 = (의류품목 가격 - 대여항목 가격)의 합 + 할인항목의 가격의 합
    최종대여가격(대여가격) = 정상금액 - 할인금액

=cut

sub price {
    my ( $self, $order ) = @_;
    return 0 unless $order;

    my $price = 0;
    ## 온라인의 경우 결제전에는 대여비를 계산해주어야 한다
    my $status_id = $order->status_id;
    if ( $order->online and "$CHOOSE_CLOTHES $CHOOSE_ADDRESS $PAYMENT $PAYMENT_DONE $WAITING_DEPOSIT $PAYBACK" =~ m/\b$status_id\b/ ) {
        my $details = $order->order_details;
        while ( my $detail = $details->next ) {
            my $name = $detail->name;
            next unless $name =~ m/^[a-z]/;

            $price += $detail->price;
        }
    }
    else {
        my @details = $order->order_details( { stage => 0, clothes_code => { '!=' => undef } } );
        ## 대여금액이 아닌 정상금액을 계산하는 것이므로 clothes.price 의 합을 구한다
        for my $detail (@details) {
            my $clothes = $detail->clothes;
            $price += $clothes->price;
        }
    }

    return $price;
}

=head2 discount_price( $order )

    my $discount = $self->discount_price($order);    # -10000

=cut

sub discount_price {
    my ( $self, $order ) = @_;
    return 0 unless $order;

    my $price   = 0;
    my @details = $order->order_details(
        {
            stage => 0,
            -or   => [
                desc => { -like => '3회 이상 방문%' },
                name => { -in   => ['3회 이상 대여 할인'] },
                name => { -like => '%할인쿠폰' },
            ]
        }
    );

    for my $detail (@details) {
        if ( my $clothes = $detail->clothes ) {
            ## 의류품목의 가격과 항목의 가격의 차액의 합
            $price += $detail->price - $clothes->price;
        }
        else {
            ## 할인항목의 가격의 합
            $price += $detail->price;
        }
    }

    return $price;
}

=head2 overdue_days( $order, $today? )

C<$today> means C<return_date>. default is today.

연체일(오늘 - 반납희망일)

    my $overdue_days = $self->overdue_days($order);
    my $overdue_days = $self->overdue_days($order, '2017-03-14T00:00:00');

=cut

sub overdue_days {
    my ( $self, $order, $today ) = @_;
    return 0 unless $order;

    if ( !$self->{ignore} && $order->status_id == $RETURNED ) {
        my $od = $order->order_details( { name => '연체료', stage => 1 }, { rows => 1 } )->single;
        return 0 unless $od;

        my $desc = $od->desc;
        my ( $price, $rate, $days ) = split / x /, $desc;
        $days =~ s/일//;
        return $days || 0;
    }

    my $target_dt      = $order->target_date;
    my $user_target_dt = $order->user_target_date;
    my $return_dt      = $order->return_date;

    return 0 unless $target_dt;
    return 0 unless $user_target_dt;

    unless ($return_dt) {
        my $tz = $self->{timezone};
        if ( $today && $today =~ m/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$/ ) {
            my $pattern = $today =~ /T/ ? q{%FT%T} : q{%F %T};
            my $strp = DateTime::Format::Strptime->new(
                pattern   => $pattern,
                time_zone => $tz,
                on_error  => 'undef',
            );

            my $dt = $strp->parse_datetime($today);
            $today = $dt->truncate( to => 'day' ) if $dt;
        }
        else {
            $today = DateTime->today( time_zone => $tz );
        }

        $return_dt = $today;
    }

    $target_dt = $target_dt->clone->truncate( to => 'day' );
    $user_target_dt = $user_target_dt->clone->truncate( to => 'day' );
    $return_dt = $return_dt->clone->truncate( to => 'day' );

    my $target_epoch      = $target_dt->epoch;
    my $return_epoch      = $return_dt->epoch;
    my $user_target_epoch = $user_target_dt->epoch;

    return 0 if $target_epoch >= $return_epoch;
    return 0 if $user_target_epoch >= $return_epoch;

    my $dur = $return_epoch - $user_target_epoch;

    return 0 if $dur <= 0;
    return int( $dur / $DAY_AS_SECONDS );
}

=head2 overdue_fee( $order, $today? )

    # 연체비 = 연체일 * 대여비 * $OVERDUE_RATE
    my $overdue_fee = $self->overdue_days($order);

=cut

sub overdue_fee {
    my ( $self, $order, $today ) = @_;

    if ( !$self->{ignore} && $order->status_id == $RETURNED ) {
        my $od = $order->order_details( { name => '연체료', stage => 1 }, { rows => 1 } )->single;
        return 0 unless $od;

        my $desc = $od->desc;
        my ( $price, $rate, $days ) = split / x /, $desc;
        $price =~ s/,//;
        $price =~ s/원//;
        $rate =~ s/%//;
        $rate /= 100;
        $days =~ s/일//;

        return $price * $rate * $days || 0;
    }
    else {
        my $price    = $self->price($order);
        my $discount = $self->discount_price($order);
        my $days     = $self->overdue_days( $order, $today );

        my $coupon = $order->coupon;
        if ( $coupon and $coupon->type eq 'suit' ) {
            ## suit type 쿠폰일때는 정상금액을 기준으로 계산
        }
        else {
            ## 이외에는 대여금액으로 계산: 대여금액 = 정상금액 - 할인금액
            $price += $discount;
        }

        return $price * $OVERDUE_RATE * $days;
    }
}

=head2 extension_days( $order, $today? )

연장일(반납희망일 - 반납예정일)

    my $ext_days = $self->extension_days($order);

=cut

sub extension_days {
    my ( $self, $order, $today ) = @_;
    return 0 unless $order;

    if ( !$self->{ignore} && $order->status_id == $RETURNED ) {
        my $od = $order->order_details( { name => '연장료', stage => 1 }, { rows => 1 } )->single;
        return 0 unless $od;

        my $desc = $od->desc;
        my ( $price, $rate, $days ) = split / x /, $desc;
        $days =~ s/일//;
        return $days || 0;
    }

    my $target_dt      = $order->target_date;
    my $user_target_dt = $order->user_target_date;
    my $return_dt      = $order->return_date;

    return 0 unless $target_dt;
    return 0 unless $user_target_dt;

    unless ($return_dt) {
        my $tz = $self->{timezone};
        if ( $today && $today =~ m/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$/ ) {
            my $pattern = $today =~ /T/ ? q{%FT%T} : q{%F %T};
            my $strp = DateTime::Format::Strptime->new(
                pattern   => $pattern,
                time_zone => $tz,
                on_error  => 'undef',
            );

            my $dt = $strp->parse_datetime($today);
            $today = $dt->truncate( to => 'day' ) if $dt;
        }
        else {
            $today = DateTime->today( time_zone => $tz );
        }

        $return_dt = $today;
    }

    $target_dt = $target_dt->clone->truncate( to => 'day' );
    $user_target_dt = $user_target_dt->clone->truncate( to => 'day' );
    $return_dt = $return_dt->clone->truncate( to => 'day' );

    my $target_epoch      = $target_dt->epoch;
    my $return_epoch      = $return_dt->epoch;
    my $user_target_epoch = $user_target_dt->epoch;

    return 0 if $target_epoch >= $return_epoch;

    my $dur;
    if ( $user_target_epoch - $return_epoch > 0 ) {
        $dur = $return_epoch - $target_epoch;
    }
    else {
        $dur = $user_target_epoch - $target_epoch;
    }

    return 0 if $dur <= 0;
    return int( $dur / $DAY_AS_SECONDS );
}

=head2 extension_fee( $order, $today? )

    # 연장비 = 연장일 * 대여비 * $EXTENSION_RATE
    my $extension_fee = $calc->extension_fee($order);

=cut

sub extension_fee {
    my ( $self, $order, $today ) = @_;

    if ( !$self->{ignore} && $order->status_id == $RETURNED ) {
        my $od = $order->order_details( { name => '연장료', stage => 1 }, { rows => 1 } )->single;
        return 0 unless $od;

        my $desc = $od->desc;
        my ( $price, $rate, $days ) = split / x /, $desc;
        $price =~ s/,//;
        $price =~ s/원//;
        $rate =~ s/%//;
        $rate /= 100;
        $days =~ s/일//;

        return $price * $rate * $days || 0;
    }
    else {
        my $price    = $self->price($order);
        my $discount = $self->discount_price($order);
        my $days     = $self->extension_days( $order, $today );

        my $coupon = $order->coupon;
        if ( $coupon and $coupon->type eq 'suit' ) {
            ## suit type 쿠폰일때는 정상금액을 기준으로 계산
        }
        else {
            ## 이외에는 대여금액으로 계산: 대여금액 = 정상금액 - 할인금액
            $price += $discount;
        }

        return $price * $EXTENSION_RATE * $days;
    }
}

=head2 late_fee( $order, $today? )

    # 연장비 + 연체비
    my $late_fee = $calc->late_fee($order);

=cut

sub late_fee {
    my ( $self, $order, $today ) = @_;

    my $extension_fee = $self->extension_fee( $order, $today );
    my $overdue_fee = $self->overdue_fee( $order, $today );
    return $extension_fee + $overdue_fee;
}

1;

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 열린옷장

=cut

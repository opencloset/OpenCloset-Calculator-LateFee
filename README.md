# OpenCloset-Calculator-LateFee #

late_fee(연체비+연장비), overdue_fee(연체비) and extension_fee(연장비) calculator

## Requirements ##

    $ cpanm --installdeps .

## Synopsis ##

    my $calc         = OpenCloset::Calculator::LateFee->new;
    my $overdue_days = $calc->overdue_days($order);   # 연체일: 오늘 - 반납희망일
    my $overdue_fee  = $calc->overdue_fee($order);    # 연체료: 대여비 * 연체일 * 0.3
    my $ext_days     = $calc->extension_days($order); # 연장일: 반납희망일 - 반납예정일
    my $ext_fee      = $calc->extension_fee($order);  # 연장비: 대여비 * 연장일 * 0.2
    my $late_fee     = $calc->late_fee($order);       # 연장비 + 연체비

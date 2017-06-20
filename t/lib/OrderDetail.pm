package OrderDetail;

use Clothes;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub clothes {
    return Clothes->new;
}

sub price {
    return 5000;
}

## using at discount_price
sub final_price {
    return 0;
}

1;

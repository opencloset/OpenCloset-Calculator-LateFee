package Clothes;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub price {
    return 5000;
}

1;
